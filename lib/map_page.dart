// ✅ 통합 MapPage - 게시글 기반 지도 + 내 위치 기반 필터링 지원
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../databaseSvc.dart';
import '../home_page/post_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int selectedIndex = 0;
  GoogleMapController? _mapController;

  LatLng? _myLatLng;
  Marker? _myMarker;
  final double _searchRadius = 5.0;

  double _calculateDistance(LatLng a, LatLng b) {
    const R = 6371;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final aVal = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(a.latitude)) * cos(_toRadians(b.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(aVal));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  List<RecruitPost> _filterPostsByRadius(List<RecruitPost> posts) {
    if (_myLatLng == null) return posts;
    return posts.where((post) {
      final postLatLng = LatLng(post.location.latitude, post.location.longitude);
      final distance = _calculateDistance(_myLatLng!, postLatLng);
      return distance <= _searchRadius;
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

  Future<void> _moveToMyLocation() async {
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
        child: StreamBuilder<List<RecruitPost>>(
          stream: RecruitPostDBS.getPostsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allPosts = snapshot.data!;
            final filteredPosts = _filterPostsByRadius(allPosts);
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
                  Positioned(
                    top: 20,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: 'myLocationBtn',
                      backgroundColor: Colors.white,
                      onPressed: _moveToMyLocation,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
                  Center(
                    child: _myLatLng != null
                        ? const Text('주변에 게시글이 없습니다.')
                        : const Text('게시글이 없습니다. 내 위치를 활성화하여 주변 게시글을 확인하세요.'),
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
                  top: 20,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'myLocationBtn',
                    backgroundColor: Colors.white,
                    onPressed: _moveToMyLocation,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
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
