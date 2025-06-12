import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_detail_page.dart';
import 'my_post_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? profileImageUrl;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        profileImageUrl = data?['profileImage'];
        email = data?['email'];
      });
    }
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
    final currentUser = FirebaseAuth.instance.currentUser;
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
        padding: const EdgeInsets.symmetric(vertical: 30),
        children: [
          Center(
            child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? CircleAvatar(
              radius: 50,
              backgroundColor: appBarColor,
              backgroundImage: NetworkImage(profileImageUrl!),
            )
                : const CircleAvatar(
              radius: 50,
              backgroundColor: appBarColor,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              email ?? currentUser?.email ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),

          buildTappableTile(
            icon: Icons.person,
            title: "프로필",
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
            icon: Icons.settings,
            title: "설정",
            onTap: () {
              // 설정 페이지 연결 가능
            },
          ),

          buildTappableTile(
            icon: Icons.logout,
            title: "로그아웃",
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
