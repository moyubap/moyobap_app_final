import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_detail_page.dart';

<<<<<<< HEAD

=======
>>>>>>> b0ec3c9 (Initial commit)
class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFB3E5FC);
=======
  Future<Map<String, dynamic>> fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    final postSnap = await FirebaseFirestore.instance
        .collection('posts')
        .where('hostId', isEqualTo: userId)
        .get();

    final chatSnap = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('members', arrayContains: userId)
        .get();

    return {
      'nickname': userData['nickname'] ?? '알 수 없음',
      'intro': userData['intro'] ?? '없음',
      'profileImage': userData['profileImage'] ?? '',
      'likedFoods': List<String>.from(userData['likedFoods'] ?? []),
      'dislikedFoods': List<String>.from(userData['dislikedFoods'] ?? []),
      'postCount': postSnap.docs.length,
      'chatCount': chatSnap.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB3E5FC);
>>>>>>> b0ec3c9 (Initial commit)

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
<<<<<<< HEAD
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
=======
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '상대방 프로필',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
>>>>>>> b0ec3c9 (Initial commit)
        ),
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null || currentUser.uid == userId) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('자기 자신과 채팅할 수 없습니다.')),
              );
              return;
            }
            final uids = [currentUser.uid, userId]..sort();
            final chatRoomId = uids.join('_');
            final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
            final snapshot = await chatRoomRef.get();
            if (!snapshot.exists) {
              await chatRoomRef.set({
                'members': uids,
                'createdAt': FieldValue.serverTimestamp(),
                'lastMessage': '',
              });
            }
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(
                    otherUserId: userId,
                    chatRoomId: chatRoomId,
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.chat),
          label: const Text('채팅하기', style: TextStyle(fontSize: 17)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
<<<<<<< HEAD
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
=======
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final nickname = data['nickname'];
          final intro = data['intro'];
          final image = data['profileImage'];
          final likedFoods = data['likedFoods'];
          final dislikedFoods = data['dislikedFoods'];
          final postCount = data['postCount'];
          final chatCount = data['chatCount'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                image != ''
                    ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(image))
                    : const CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // 한 줄 소개
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('한 줄 소개', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(intro),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 좋아하는 음식
                if (likedFoods.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('좋아하는 음식', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: likedFoods.map<Widget>((f) => Chip(label: Text(f))).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 싫어하는 음식
                if (dislikedFoods.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('싫어하는 음식', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: dislikedFoods.map<Widget>((f) => Chip(label: Text(f))).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // 모집글, 채팅 신청 수
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
>>>>>>> b0ec3c9 (Initial commit)
          );
        },
      ),
    );
  }
}
