import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page/home_page.dart';
import 'map_page.dart';
import 'chat/chat_list_page.dart';
import 'mypage/my_page.dart';

import 'login/login.dart';
import 'login/signup.dart';
import 'login/loginPhone.dart';
import 'home_page/location_picker_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모여밥',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFFDFDFD),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/main': (context) => const MainPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/login-phone': (context) => const LoginPhonePage(),
        '/locationPicker': (context) => const LocationPickerPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainPage();
        }
        return const LoginPage();
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const MapPage(),
    const ChatListPage(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateMyStatus(isOnline: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateMyStatus(isOnline: false); // 앱 종료시 오프라인 처리(옵션)
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱 포그라운드/백그라운드 상태 반영 (선택)
    if (state == AppLifecycleState.resumed) {
      _updateMyStatus(isOnline: true);
    } else if (state == AppLifecycleState.paused) {
      _updateMyStatus(isOnline: false);
    }
  }

  Future<void> _updateMyStatus({required bool isOnline}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.set({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
      if (pos != null)
        'location': GeoPoint(pos.latitude, pos.longitude),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
              // 페이지 이동시에도 상태 갱신 (옵션)
              _updateMyStatus(isOnline: true);
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: const Color(0xFF42A5F5),
          unselectedItemColor: const Color(0xFFB0BEC5),
          selectedIconTheme: const IconThemeData(
            size: 28,
            shadows: [
              Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
            ],
          ),
          unselectedIconTheme: const IconThemeData(size: 24),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map, size: 25),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                currentIndex == 2 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                size: 23,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                currentIndex == 3 ? Icons.person : Icons.person_outline,
                size: 26,
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
