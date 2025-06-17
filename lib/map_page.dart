//  통합 MapPage - 게시글 기반 지도 + 내 위치 기반 필터링 지원
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../databaseSvc.dart';
import '../home_page/post_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page/user_profile_page.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

enum MapFilterType { allPosts, nearbyPosts, nearbyFriends }

class _MapPageState extends State<MapPage> {
  int selectedIndex = 0;
  GoogleMapController? _mapController;

  LatLng? _myLatLng;
  Marker? _myMarker;
  final double _searchRadius = 2.0; // 2km

  MapFilterType _currentFilter = MapFilterType.allPosts;

  List<RecruitPost> _filterPostsByRadius(List<RecruitPost> posts) {
    if (_myLatLng == null) return posts;
    return posts.where((post) {
      final postLatLng = LatLng(post.location.latitude, post.location.longitude);
      final distance = Geolocator.distanceBetween(
        _myLatLng!.latitude,
        _myLatLng!.longitude,
        postLatLng.latitude,
        postLatLng.longitude,
      );
      return distance <= _searchRadius * 1000;
    }).toList();
  }

  List<Map<String, dynamic>> _filterFriendsByRadius(List<Map<String, dynamic>> friends) {
    if (_myLatLng == null) return [];
    return friends.where((friend) {
      if (friend['uid'] == null ||
          friend['location'] == null ||
          !(friend['isOnline'] ?? false)) return false;
      final geo = friend['location'] as GeoPoint;
      final friendLatLng = LatLng(geo.latitude, geo.longitude);
      final distance = Geolocator.distanceBetween(
        _myLatLng!.latitude,
        _myLatLng!.longitude,
        friendLatLng.latitude,
        friendLatLng.longitude,
      );
      final lastActive = friend['lastActive'] as Timestamp?;
      final isRecentlyActive = lastActive != null &&
          DateTime.now().difference(lastActive.toDate()).inMinutes < 5;
      return isRecentlyActive && distance <= _searchRadius * 1000;
    }).toList();
  }

  void selectPost(int index, List<RecruitPost> posts) {
    if (index < 0 || index >= posts.length) return;
    setState(() => selectedIndex = index);
    final post = posts[index];
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(post.location.latitude, post.location.longitude),
      ),
    );
  }

  Future<void> _setMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('위치 서비스가 꺼져있습니다.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('위치 권한이 거부되었습니다.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack('위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요.');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _myLatLng = LatLng(pos.latitude, pos.longitude);
      _myMarker = Marker(
        markerId: const MarkerId('myLocation'),
        position: _myLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: "내 위치"),
      );
      selectedIndex = 0;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(_myLatLng!));
  }


  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Stream<List<Map<String, dynamic>>> getFriendsStream() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data()..['uid'] = doc.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFAEDCF7),
        centerTitle: true,
        title: const Text('지도', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. GoogleMap (항상 맨 아래)
            Positioned.fill(
              child: _currentFilter == MapFilterType.nearbyFriends
                  ? StreamBuilder<List<Map<String, dynamic>>>(
                stream: getFriendsStream(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final friends = _filterFriendsByRadius(userSnap.data!);

                  final markers = {
                    if (_myMarker != null) _myMarker!,
                    ...friends.map(
                          (friend) {
                        final geo = friend['location'] as GeoPoint;
                        return Marker(
                          markerId: MarkerId('friend_${friend['uid']}'),
                          position: LatLng(geo.latitude, geo.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          infoWindow: InfoWindow(
                            title: friend['nickname'] ?? friend['uid'],
                            snippet: '2km 내 친구',
                          ),
                        );
                      },
                    ),
                  };

                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _myLatLng ?? const LatLng(37.5665, 126.9780),
                          zoom: 15,
                        ),
                        markers: markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_myLatLng != null) {
                            _mapController?.animateCamera(CameraUpdate.newLatLng(_myLatLng!));
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                      // 하단 친구 카드 리스트
                      if (friends.isNotEmpty)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                final friend = friends[index];
                                return FriendProfileCard(
                                  friend: friend,
                                  onMorePressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserProfilePage(
                                          userId: friend['uid'],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
                  : StreamBuilder<List<RecruitPost>>(
                stream: RecruitPostDBS.getPostsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final allPosts = snapshot.data!;
                  final filteredPosts = _currentFilter == MapFilterType.nearbyPosts
                      ? _filterPostsByRadius(allPosts)
                      : allPosts;
                  if (filteredPosts.isEmpty) {
                    return Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _myLatLng ?? const LatLng(37.5665, 126.9780),
                            zoom: 15,
                          ),
                          markers: {if (_myMarker != null) _myMarker!},
                          onMapCreated: (c) => _mapController = c,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                        Center(
                          child: _myLatLng != null
                              ? Text(_currentFilter == MapFilterType.nearbyFriends
                              ? '주변에 친구가 없습니다.'
                              : '주변에 게시글이 없습니다.')
                              : const Text('내 위치를 활성화하세요.'),
                        ),
                      ],
                    );
                  }
                  if (selectedIndex >= filteredPosts.length) selectedIndex = 0;
                  final selected = filteredPosts[selectedIndex];
                  final markers = {
                    ...filteredPosts.asMap().entries.map(
                          (e) => Marker(
                        markerId: MarkerId(e.value.postId),
                        position: LatLng(e.value.location.latitude, e.value.location.longitude),
                        infoWindow: InfoWindow(
                          title: e.value.title,
                          snippet: e.value.placeName,
                          onTap: () => selectPost(e.key, filteredPosts),
                        ),
                      ),
                    ),
                    if (_myMarker != null) _myMarker!,
                  };
                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(selected.location.latitude, selected.location.longitude),
                          zoom: 15,
                        ),
                        markers: markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_myLatLng != null) {
                            _mapController?.animateCamera(CameraUpdate.newLatLng(_myLatLng!));
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 240,
                          child: PageView.builder(
                            itemCount: filteredPosts.length,
                            controller: PageController(initialPage: selectedIndex),
                            onPageChanged: (index) => selectPost(index, filteredPosts),
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: RecruitPostCard(
                                post: filteredPosts[index],
                                onMorePressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailPage(post: filteredPosts[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. 토글 버튼 (항상 Stack의 맨 마지막! 지도 위에 보임)
            Positioned(
              top: MediaQuery.of(context).padding.top + 6,
              left: 6,
              child: Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.97),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('전체'),
                        selected: _currentFilter == MapFilterType.allPosts,
                        onSelected: (_) => setState(() => _currentFilter = MapFilterType.allPosts),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('내 주변 모집글'),
                        selected: _currentFilter == MapFilterType.nearbyPosts,
                        onSelected: (_) async {
                          setState(() => _currentFilter = MapFilterType.nearbyPosts);
                          if (_myLatLng == null) {
                            await _setMyLocation();
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('내 주변 친구'),
                        selected: _currentFilter == MapFilterType.nearbyFriends,
                        onSelected: (_) async {
                          setState(() => _currentFilter = MapFilterType.nearbyFriends);
                          if (_myLatLng == null) {
                            await _setMyLocation();
                          }
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecruitPostCard extends StatelessWidget {
  final RecruitPost post;
  final VoidCallback onMorePressed;

  const RecruitPostCard({
    super.key,
    required this.post,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text('만남 장소: ${post.placeName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('모집 내용:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('음식:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(post.foodType, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('정원: ${post.maxParticipants}명', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onMorePressed,
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF42A5F5)),
                child: const Text('더 자세히 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FriendProfileCard extends StatelessWidget {
  final Map<String, dynamic> friend;
  final VoidCallback onMorePressed;

  const FriendProfileCard({
    super.key,
    required this.friend,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundImage: friend['profileImageUrl'] != null
                      ? NetworkImage(friend['profileImageUrl'])
                      : null,
                  child: friend['profileImageUrl'] == null
                      ? const Icon(Icons.person, size: 27)
                      : null,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    friend['nickname'] ?? friend['uid'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              friend['bio'] ?? '자기소개 없음',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onMorePressed,
                child: const Text('더 자세히 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
