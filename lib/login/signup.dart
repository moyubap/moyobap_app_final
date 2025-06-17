import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // 🔸 로그인 페이지로 이동하려면 이 import 필요

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();

  bool _isLoading = false;

  final Color mainColor = const Color(0xFFAEDCF7);
  final Color focusBlue = const Color(0xFF42A5F5);

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _pwdController.text.trim(),
        );

        final uid = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _emailController.text.trim(),
          'uid': uid,
          'nickname': '익명',
          'bio': '',
          'profileImage': null,
          'createdAt': Timestamp.now(),
        });

        // ✅ 자동 로그인 끊고 로그인 페이지로 이동
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인 해주세요.')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message = '회원가입 실패';
        if (e.code == 'email-already-in-use') {
          message = '이미 사용 중인 이메일입니다.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontSize: 18),
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
            "회원가입",
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
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  cursorColor: focusBlue,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (value) =>
                  value!.isEmpty ? '이메일을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pwdController,
                  obscureText: true,
                  cursorColor: focusBlue,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  validator: (value) =>
                  value!.length < 6 ? '비밀번호는 6자 이상이어야 합니다' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _signup,
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
