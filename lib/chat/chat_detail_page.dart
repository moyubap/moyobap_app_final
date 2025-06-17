import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ChatDetailPage extends StatefulWidget {
  final String otherUserId;
  final String chatRoomId;

  const ChatDetailPage({
    Key? key,
    required this.otherUserId,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _userNicknames = {};

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioFilePath;

  String? otherUserProfileUrl;
  String? otherUserEmail;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _recorder = FlutterSoundRecorder();
    _loadOtherUserProfile();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.storage,
      Permission.camera,
      Permission.photos,
    ].request();
  }

  String getChatRoomId() {
    List<String> ids = [currentUser!.uid, widget.otherUserId];
    ids.sort();
    return ids.join("_");
  }

  Future<void> _loadOtherUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        otherUserProfileUrl = data['profileImage'];
        otherUserEmail = data['email'];
      });
    }
  }

  Future<String> _getNickname(String userId) async {
    if (_userNicknames.containsKey(userId)) return _userNicknames[userId]!;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String nickname = doc.data()?['nickname'] ?? '알수없음';
    _userNicknames[userId] = nickname;
    return nickname;
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatRoomId = getChatRoomId();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.otherUserId,
      'text': text,
      'timestamp': Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.otherUserId)
        .collection('items')
        .add({
      'type': 'text',
      'senderId': currentUser!.uid,
      'content': text,
      'timestamp': Timestamp.now(),
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendImageMessage(File imageFile) async {
    final chatRoomId = getChatRoomId();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('chat_images/$chatRoomId/$fileName');

    final uploadTask = await ref.putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.otherUserId,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.otherUserId)
        .collection('items')
        .add({
      'type': 'image',
      'senderId': currentUser!.uid,
      'content': '사진',
      'timestamp': Timestamp.now(),
    });
  }

  Future<String?> sttWithNaver(File audioFile) async {
    final String clientId = 'cwu02jjjiv';
    final String clientSecret = 'vrZrEU6Ffc58Z01vJ6wIGZWW9mPBSQD1OdHPiwIr';

    final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/recog/v1/stt?lang=Kor');
    final headers = {
      'X-NCP-APIGW-API-KEY-ID': clientId,
      'X-NCP-APIGW-API-KEY': clientSecret,
      'Content-Type': 'application/octet-stream',
    };

    final audioBytes = await audioFile.readAsBytes();
    final response = await http.post(url, headers: headers, body: audioBytes);

    if (response.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(response.bodyBytes));
      return jsonData['text'] as String?;
    } else {
      return null;
    }
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _audioFilePath = '${dir.path}/temp_sound.aac';

    await _recorder.openRecorder();
    await _recorder.startRecorder(toFile: _audioFilePath, codec: Codec.aacADTS);

    setState(() => _isRecording = true);
  }

  Future<File?> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    if (path != null) return File(path);
    return null;
  }

  void _onMicButtonPressed() async {
    if (!_isRecording) {
      await _startRecording();
    } else {
      final audioFile = await _stopRecording();
      if (audioFile != null) {
        final result = await sttWithNaver(audioFile);
        if (result != null && result.isNotEmpty) {
          setState(() => _messageController.text = result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('STT 변환 실패')),
          );
        }
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('사진 선택'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
              if (image != null) sendImageMessage(File(image.path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('카메라로 촬영'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
              if (photo != null) sendImageMessage(File(photo.path));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomId = getChatRoomId();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: otherUserProfileUrl != null
                  ? NetworkImage(otherUserProfileUrl!)
                  : const AssetImage('assets/users/profile1.jpg') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(otherUserEmail ?? '상대방'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;

                    if (data.containsKey('imageUrl')) {
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: Image.network(
                            data['imageUrl'],
                            width: 200,
                          ),
                        ),
                      );
                    }

                    return FutureBuilder<String>(
                      future: _getNickname(data['senderId']),
                      builder: (context, snapshot) {
                        final nickname = snapshot.data ?? '...';
                        return Container(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(nickname, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  data['text'] ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
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
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.attach_file), onPressed: _showAttachmentOptions),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      cursorColor: Color(0xFF42A5F5),
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2.0),
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                    color: _isRecording ? Colors.red : Colors.black,
                    onPressed: _onMicButtonPressed,
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: sendMessage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
