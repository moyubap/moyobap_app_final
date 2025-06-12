import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(currentUser.uid)
        .collection('items')
        .orderBy('timestamp', descending: true);

    const Color appMainBlue = Color(0xFFADDDFB); // 공통 하늘색으로 수정
    const Color tileIconColor = Color(0xFF42A5F5);
    const Color tileTextColor = Color(0xFF37474F);
    const Color tileSubTextColor = Color(0xFF90A4AE);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appMainBlue,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('알림이 없습니다.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? 'text';
              final text = data['text'] ?? '';
              final senderId = data['senderId'] ?? '';

              String displayText = type == 'image'
                  ? '사진을 받았습니다.'
                  : '메시지: $text';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: Icon(Icons.notifications, color: tileIconColor, size: 28),
                title: Text(
                  displayText,
                  style: const TextStyle(
                    color: tileTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '보낸 사람: $senderId',
                  style: const TextStyle(
                    color: tileSubTextColor,
                    fontSize: 13,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white,
              );
            },
          );
        },
      ),
    );
  }
}
