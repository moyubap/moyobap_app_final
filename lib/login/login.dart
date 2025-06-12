import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();

  bool _isLoading = false;

  final Color mainColor = const Color(0xFFAEDCF7);
  final Color focusBlue = const Color(0xFF42A5F5); // 진한 블루

  void _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _pwdController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'uid': uid,
          'nickname': '익명',
          'bio': '',
          'profileImage': null,
          'createdAt': Timestamp.now(),
        });
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = '로그인 실패';
      if (e.code == 'user-not-found') msg = '등록되지 않은 사용자입니다';
      else if (e.code == 'wrong-password') msg = '비밀번호가 일치하지 않습니다';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("오류가 발생했습니다.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: mainColor,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: focusBlue,
          secondary: focusBlue,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: focusBlue),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontSize: 18), // ✅ 버튼 텍스트 크기
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: focusBlue, width: 2),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "로그인",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  cursorColor: focusBlue,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (value) => value!.isEmpty ? '이메일을 입력하세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pwdController,
                  obscureText: true,
                  cursorColor: focusBlue,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  validator: (value) => value!.length < 6 ? '비밀번호는 6자 이상' : null,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _loginUser,
                  child: const Text("로그인"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login-phone'),
                  child: const Text("전화번호로 로그인"),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("계정이 없으신가요? 회원가입"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
