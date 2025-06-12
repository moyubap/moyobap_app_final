import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFB3E5FC);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2)],
        ),
        title: const Text(
          '상대방 프로필',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2)],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("사용자 정보 없음"));

          final nickname = data['nickname'] ?? '알 수 없음';
          final oneLinerRaw = data['bio']; // ✅ 'bio'로 바꿈
          final oneLiner = (oneLinerRaw == null || oneLinerRaw.toString().trim().isEmpty)
              ? '없음'
              : oneLinerRaw.toString();

          final favoriteFoods = data['likes'] is List ? List<String>.from(data['likes']) : [];
          final dislikesRaw = data['dislikes'];
          final dislikes = (dislikesRaw == null || dislikesRaw.toString().trim().isEmpty)
              ? '없음'
              : dislikesRaw.toString();

          final profileImage = data['profileImage'];

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('posts')
                .where('hostId', isEqualTo: userId)
                .get(),
            builder: (context, postSnap) {
              final postCount = postSnap.data?.docs.length ?? 0;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .where('members', arrayContains: userId)
                    .get(),
                builder: (context, chatSnap) {
                  final chatCount = chatSnap.data?.docs.length ?? 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        profileImage != null && profileImage != ''
                            ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(profileImage),
                        )
                            : const CircleAvatar(
                          radius: 50,
                          backgroundColor: primaryColor,
                          child: Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('한 줄 소개', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Align(alignment: Alignment.centerLeft, child: Text(oneLiner)),

                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('좋아하는 음식', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: favoriteFoods.isEmpty
                              ? const Text('없음')
                              : Text(favoriteFoods.join(', '), style: const TextStyle(fontSize: 16)),
                        ),

                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('싫어하는 음식', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Align(alignment: Alignment.centerLeft, child: Text(dislikes)),

                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_note, size: 20, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text('모집 글: $postCount회'),

                            const SizedBox(width: 24),

                            const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text('채팅 신청: $chatCount회'),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
