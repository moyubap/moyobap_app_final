import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'write_page.dart';
import '../databaseSvc.dart';
import 'user_profile_page.dart';
import '../chat/chat_detail_page.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});
  final RecruitPost post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool isLiked = false;
  int likeCount = 0;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likes.contains(currentUser?.uid);
    likeCount = widget.post.likes.length;

    FirebaseFirestore.instance.collection('posts').doc(widget.post.postId).update({
      'views': FieldValue.increment(1),
    });
  }

  void toggleLike() async {
    if (currentUser == null) return;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.postId);

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    await postRef.update({
      'likes': isLiked
          ? FieldValue.arrayUnion([currentUser!.uid])
          : FieldValue.arrayRemove([currentUser!.uid])
    });
  }

  bool get isMyPost => currentUser != null && widget.post.hostId == currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    const Color appMainBlue = Color(0xFFADDDFB);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: appMainBlue,
        elevation: 0,
        title: Text(
          post.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: isMyPost
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WritePage(post: post))),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("정말 삭제하시겠습니까?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제")),
                  ],
                ),
              );
              if (confirmed == true) {
                await FirebaseFirestore.instance.collection('posts').doc(post.postId).delete();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                post.imageUrl != null && post.imageUrl!.isNotEmpty
                    ? Image.network(post.imageUrl!, width: double.infinity, height: 260, fit: BoxFit.cover)
                    : Image.asset('assets/images/lunch.jpeg', width: double.infinity, height: 260, fit: BoxFit.cover),
                Container(
                  color: const Color(0xFFFFFEFC),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(post.hostId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final raw = snapshot.data!.data();
                          if (raw == null) return const SizedBox.shrink();
                          final user = raw as Map<String, dynamic>;
                          final nickname = user['nickname'] ?? post.hostId;
                          final profileUrl = user['profileImage'];

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UserProfilePage(userId: post.hostId)),
                            ),
                            child: Row(
                              children: [
                                profileUrl != null && profileUrl.isNotEmpty
                                    ? CircleAvatar(
                                  backgroundImage: NetworkImage(profileUrl),
                                  radius: 22,
                                )
                                    : CircleAvatar(
                                  radius: 22,
                                  backgroundColor: appMainBlue,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nickname, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const Text('작성자', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _infoSection(post),
                      const SizedBox(height: 24),
                      Text(post.content, style: const TextStyle(height: 1.8, fontSize: 16)),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          IconButton(
                            onPressed: toggleLike,
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.black,
                            ),
                          ),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('posts').doc(post.postId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              final views = data['views'] ?? 0;
                              return Text('관심 $likeCount ∙ 조회수 $views',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(thickness: 0.5, color: Colors.black12),
                      const SizedBox(height: 12),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('posts').doc(post.postId).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final participants = data['participantIds'] as List<dynamic>? ?? [];
                          final participantCount = participants.length;
                          final maxCount = data['maxParticipants'] ?? 0;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people, color: Colors.lightBlue),
                                const SizedBox(width: 8),
                                Text('신청 인원 $participantCount명 / 모집 인원 $maxCount명',
                                    style: const TextStyle(color: Colors.black87, fontSize: 15)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          _chatButton(post, appMainBlue),
        ],
      ),
    );
  }

  Widget _infoSection(RecruitPost post) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(minWidth: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(post.placeName)}');
                if (!await launchUrl(uri)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('지도를 열 수 없습니다.')),
                  );
                }
              },
              child: _iconRow(Icons.place, post.placeName, Colors.redAccent, underline: true, linkColor: Colors.blue),
            ),
            const SizedBox(height: 12),
            _iconRow(Icons.calendar_today, post.meetTime.toDate().toString().split(" ")[0], Colors.green),
            const SizedBox(height: 12),
            _iconRow(Icons.access_time, post.meetTime.toDate().toString().split(" ")[1].substring(0, 5), Colors.deepPurple),
            const SizedBox(height: 12),
            _iconRow(Icons.restaurant, post.foodType, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _chatButton(RecruitPost post, Color appMainBlue) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            final otherUserId = post.hostId;
            if (currentUser == null || currentUser.uid == otherUserId) return;

            final uids = [currentUser.uid, otherUserId]..sort();
            final chatRoomId = uids.join('_');
            final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
            final postRef = FirebaseFirestore.instance.collection('posts').doc(post.postId);

            final snapshot = await chatRoomRef.get();
            if (!snapshot.exists) {
              await chatRoomRef.set({
                'members': uids,
                'createdAt': FieldValue.serverTimestamp(),
                'lastMessage': '',
              });
            } else {
              await chatRoomRef.update({
                'members': FieldValue.arrayUnion([currentUser.uid])
              });
            }

            await postRef.update({
              'participantIds': FieldValue.arrayUnion([currentUser.uid]),
            });

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(
                    otherUserId: otherUserId,
                    chatRoomId: chatRoomId,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: appMainBlue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 4,
            shadowColor: Colors.black45,
          ),
          child: const Text('채팅 신청하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 1)],
              )),
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String label, Color iconColor,
      {bool underline = false, Color? linkColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: linkColor ?? Colors.black87,
            decoration: underline ? TextDecoration.underline : null,
            decorationColor: underline ? linkColor ?? Colors.black87 : null,
            decorationThickness: underline ? 2.0 : null,
            fontWeight: underline ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
