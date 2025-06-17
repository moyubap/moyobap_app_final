import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home_page/user_profile_page.dart';

class UsersTabPage extends StatefulWidget {
  const UsersTabPage({super.key});

  @override
  State<UsersTabPage> createState() => _UsersTabPageState();
}

class _UsersTabPageState extends State<UsersTabPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> recommendedUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Only 1 tab for recommended users
    loadUsers();
  }

  Future<void> loadUsers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> recommended = [];

    // 내 좋아요 목록 안전하게 파싱
    final currentUserDoc = snapshot.docs.firstWhere((doc) => doc.id == uid);
    final currentData = currentUserDoc.data();
    final myLikesRaw = currentData['likes'];
    List<String> myLikes = [];
    if (myLikesRaw is List) {
      myLikes = List<String>.from(myLikesRaw);
    } else if (myLikesRaw is String) {
      myLikes = [myLikesRaw];
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final userId = doc.id;
      final nickname = data['nickname'];

      // 닉네임 없으면 건너뛰기
      if (nickname == null || nickname.toString().trim().isEmpty) continue;

      final profileImage = data['profileImage'] ?? '';
      final intro = data['intro'] ?? '';

      // otherLikes 안전하게 파싱
      final rawLikes = data['likes'];
      List<String> otherLikes = [];
      if (rawLikes is List) {
        otherLikes = List<String>.from(rawLikes);
      } else if (rawLikes is String) {
        otherLikes = [rawLikes];
      }

      // 나 자신은 추천 대상에서 제외
      if (userId == uid) continue;

      // 공통 좋아요 개수 계산
      final similarity = myLikes.toSet().intersection(otherLikes.toSet()).length;
      if (similarity > 0) {
        recommended.add({
          'userId': userId,
          'nickname': nickname,
          'profileImage': profileImage,
          'intro': intro,
          'similarity': similarity,
        });
      }
    }

    // 유사도 높은 순으로 정렬
    recommended.sort((a, b) => b['similarity'].compareTo(a['similarity']));

    setState(() {
      recommendedUsers = recommended.take(10).toList(); // 최대 10명 추천
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 추천 사용자'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'AI 추천 사용자'), // Only 1 tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          recommendedUsers.isEmpty
              ? const Center(child: Text('추천할 사용자가 없습니다.'))
              : ListView.builder(
            itemCount: recommendedUsers.length,
            itemBuilder: (context, index) {
              final user = recommendedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['profileImage'] != ''
                      ? NetworkImage(user['profileImage'])
                      : null,
                  child: user['profileImage'] == '' ? const Icon(Icons.person) : null,
                ),
                title: Text(user['nickname']),
                subtitle: Text(
                  '소개: ${user['intro']}\n공통 좋아요: ${user['similarity']}개',
                ),
                isThreeLine: true,
                onTap: () => openProfile(user['userId']),
              );
            },
          ),
        ],
      ),
    );
  }
}
