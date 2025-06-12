import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../databaseSvc.dart';
import 'post_detail_page.dart';

class PostItem extends StatelessWidget {
  const PostItem(this.post, {super.key});
  final RecruitPost post;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(post.meetTime.toDate());

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.placeName,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 16, color: Colors.lightBlue),
                        const SizedBox(width: 4),
                        // 🔽 신청 인원 / 모집 인원 표시
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('posts').doc(post.postId).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Text("신청 0 / ?명", style: TextStyle(fontSize: 13));
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final participants = data['participantIds'] as List<dynamic>? ?? [];
                            final max = data['maxParticipants'] ?? 0;
                            return Text(' ${participants.length} / $max명', style: const TextStyle(fontSize: 13));
                          },
                        ),
                        const SizedBox(width: 16),
                        // 🔽 관심(좋아요) 버튼 + 수 표시
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('posts').doc(post.postId).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final likes = data['likes'] ?? [];
                            final isLiked = currentUser != null && likes.contains(currentUser.uid);
                            final likeCount = (likes as List).length;

                            return GestureDetector(
                              onTap: () async {
                                if (currentUser == null) return;
                                final postRef = FirebaseFirestore.instance.collection('posts').doc(post.postId);

                                if (isLiked) {
                                  await postRef.update({
                                    'likes': FieldValue.arrayRemove([currentUser.uid])
                                  });
                                } else {
                                  await postRef.update({
                                    'likes': FieldValue.arrayUnion([currentUser.uid])
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isLiked ? Colors.pinkAccent : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('$likeCount', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 오른쪽 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                    ? Image.network(post.imageUrl!, width: 90, height: 90, fit: BoxFit.cover)
                    : Image.asset('assets/images/lunch.jpeg', width: 90, height: 90, fit: BoxFit.cover),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
