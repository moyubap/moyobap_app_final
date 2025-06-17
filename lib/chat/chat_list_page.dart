import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool isEditing = false;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _searchKeyword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFAEDCF7),
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () {
            setState(() {
              isEditing = !isEditing;
            });
          },
          child: Text(
            isEditing ? '완료' : '편집',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        centerTitle: true,
        title: const Text('채팅', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))])),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchKeyword = value),
              cursorColor: const Color(0xFF42A5F5),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '채팅방을 검색하세요',
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .where('members', arrayContains: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final chatRooms = snapshot.data!.docs;
                if (chatRooms.isEmpty) return const Center(child: Text('채팅방이 없습니다.'));

                return ListView.separated(
                  itemCount: chatRooms.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final doc = chatRooms[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final chatRoomId = doc.id;
                    final members = List<String>.from(data['members'] ?? []);
                    final otherUserId = members.firstWhere((id) => id != currentUserId, orElse: () => '');
                    final lastMessage = data['lastMessage'] ?? '';
                    final unreadCount = data['unreadCounts']?[currentUserId] ?? 0;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                        final name = userData?['nickname'] ?? otherUserId;
                        final profileUrl = userData?['profileImage'];

                        if (_searchKeyword.isNotEmpty && !name.contains(_searchKeyword)) {
                          return const SizedBox.shrink();
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: profileUrl == null || profileUrl.isEmpty
                                ? const Color(0xFFAEDCF7)
                                : Colors.transparent,
                            backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                                ? NetworkImage(profileUrl)
                                : null,
                            child: (profileUrl == null || profileUrl.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            lastMessage,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(
                                  otherUserId: otherUserId,
                                  chatRoomId: chatRoomId,
                                ),
                              ),
                            );
                          },
                          trailing: isEditing
                              ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await doc.reference.delete();
                            },
                          )
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
