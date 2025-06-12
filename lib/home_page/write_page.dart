import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../databaseSvc.dart';
import '../home_page/location_picker_page.dart';

class WritePage extends StatefulWidget {
  final RecruitPost? post;
  const WritePage({super.key, this.post});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? selectedLocation;
  String? locationUrl;
  GeoPoint? selectedGeoPoint;
  File? _selectedImage;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedMealType;
  int _selectedMaxParticipants = 2;

  final Color primaryColor = const Color(0xFFAEDCF7);

  final List<String> mealTypes = [
    '한식', '일식', '중식', '양식', '분식', '디저트', '패스트푸드',
  ];

  final List<int> maxParticipantsOptions = List.generate(10, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    if (post != null) {
      _titleController.text = post.title;
      _contentController.text = post.content;
      selectedLocation = post.placeName;
      locationUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(post.placeName)}';
      selectedGeoPoint = post.location;
      final meet = post.meetTime.toDate();
      selectedDate = DateTime(meet.year, meet.month, meet.day);
      selectedTime = TimeOfDay(hour: meet.hour, minute: meet.minute);
      selectedMealType = post.foodType;
      _selectedMaxParticipants = post.maxParticipants;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<String?> _uploadImage(String postId) async {
    if (_selectedImage == null) return null;
    final ref = FirebaseStorage.instance.ref().child('post_images/$postId.jpg');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result is Map<String, dynamic>) {
      setState(() {
        selectedLocation = result['placeName'] ?? result['name'];
        locationUrl = result['locationUrl'] ?? result['url'];
        selectedGeoPoint = result['geoPoint'] ??
            (result['lat'] != null && result['lng'] != null ? GeoPoint(result['lat'], result['lng']) : null);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: primaryColor,
              hourMinuteColor: primaryColor,
            ),
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  String get formattedDate => selectedDate == null
      ? '날짜 선택'
      : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

  String get formattedTime => selectedTime == null
      ? '시간 선택'
      : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

  Future<void> _submitPost() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        selectedMealType == null ||
        selectedLocation == null ||
        selectedGeoPoint == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목을 모두 입력하세요.')),
      );
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final postRef = widget.post == null
          ? FirebaseFirestore.instance.collection('posts').doc()
          : FirebaseFirestore.instance.collection('posts').doc(widget.post!.postId);

      final postId = postRef.id;
      final meetDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      final imageUrl = await _uploadImage(postId);

      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        'foodType': selectedMealType,
        'placeName': selectedLocation,
        'location': selectedGeoPoint,
        'meetTime': Timestamp.fromDate(meetDateTime),
        'hostId': uid,
        'createdAt': Timestamp.now(),
        'maxParticipants': _selectedMaxParticipants,
        'genderLimit': 'any',
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      if (widget.post == null) {
        data['status'] = 'open';
        data['participantIds'] = [uid];
      }

      await postRef.set(data, SetOptions(merge: true));
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('글 등록 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? '글 수정' : '글 쓰기',
          style: const TextStyle(
            fontFamily: 'UhBeeSe_hyun',
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              '임시저장',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '제목을 입력해주세요.'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '밥 친구들과 가볍게 얘기해보세요.'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage == null
                    ? const Center(child: Icon(Icons.link))
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(formattedDate, style: TextStyle(color: Color(0xFF42A5F5))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(formattedTime, style: TextStyle(color: Color(0xFF42A5F5))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMealType,
              decoration: const InputDecoration(labelText: '식사 종류 선택'),
              items: mealTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) => setState(() => selectedMealType = value),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectLocation,
              icon: Icon(Icons.place, color: Color(0xFF42A5F5)),
              label: Text(selectedLocation ?? '위치를 선택해주세요', style: TextStyle(color: Color(0xFF42A5F5))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('모집 인원:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _selectedMaxParticipants,
                  items: maxParticipantsOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e명')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMaxParticipants = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFAEDCF7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('작성 완료', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
