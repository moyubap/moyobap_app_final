import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_detail_page.dart';
import 'my_post_page.dart';
import 'recommended_foods_page.dart';
import 'users_tab_page.dart';
import '../main.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userData = doc.data();
      });
    }
  }

  Widget buildProfileCard() {
    const primaryColor = Color(0xFFAEDCF7);
    final imageUrl = userData?['profileImage'];
    final nickname = userData?['nickname'] ?? '닉네임 없음';
    final intro = userData?['intro'] ?? '한 줄 소개가 없습니다';
    final likedFoods = List<String>.from(userData?['likedFoods'] ?? []);

    return Column(
      children: [
        imageUrl != null && imageUrl.isNotEmpty
            ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(imageUrl))
            : const CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(intro, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 12),
        if (likedFoods.isNotEmpty) ...[
          const Text('좋아하는 음식', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: likedFoods.map((f) => Chip(label: Text(f))).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget buildTappableTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.black.withOpacity(0.2),
      highlightColor: Colors.black.withOpacity(0.12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Color(0xFFAEDCF7);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        children: [
          userData == null
              ? const Center(child: CircularProgressIndicator())
              : buildProfileCard(),
          const SizedBox(height: 20),

          buildTappableTile(
            icon: Icons.person,
            title: "프로필 수정",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileDetailPage()),
              );
            },
          ),
          buildTappableTile(
            icon: Icons.article,
            title: "내 글 목록",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPostsPage()),
              );
            },
          ),
          buildTappableTile(
            icon: Icons.fastfood,
            title: "AI 추천 음식",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecommendedFoodsPage()),
              );
            },
          ),
          buildTappableTile(
            icon: Icons.people,
            title: "AI 추천 사용자",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersTabPage()), // 👈 통합된 페이지 사용
              );
            },
          ),
          buildTappableTile(
            icon: Icons.settings,
            title: "설정",
            onTap: () {
              // 설정 페이지 연결
            },
          ),
          buildTappableTile(
            icon: Icons.logout,
            title: "로그아웃",
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
