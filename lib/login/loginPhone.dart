import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // ✅ AuthGate 사용

class LoginPhonePage extends StatefulWidget {
  const LoginPhonePage({super.key});

  @override
  State<LoginPhonePage> createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends State<LoginPhonePage> {
  final _key = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  bool _codeSent = false;
  late String _verificationId;

  final Color mainColor = const Color(0xFFAEDCF7);
  final Color focusBlue = const Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: mainColor,
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
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            "모여밥",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Center(
            child: Form(
              key: _key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                    val == null || val.isEmpty ? '전화번호를 입력하세요.' : null,
                    decoration: const InputDecoration(
                      hintText: '+82 10-1234-5678',
                      labelText: '전화번호',
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (!_codeSent) submitButton(),
                  const SizedBox(height: 15),
                  if (_codeSent)
                    TextFormField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                      val == null || val.isEmpty ? '인증번호를 입력하세요.' : null,
                      decoration: const InputDecoration(
                        hintText: '인증번호를 입력해주세요.',
                        labelText: '인증번호',
                      ),
                    ),
                  const SizedBox(height: 15),
                  if (_codeSent) verifyButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton submitButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_key.currentState!.validate()) {
          FirebaseAuth auth = FirebaseAuth.instance;
          await auth.verifyPhoneNumber(
            phoneNumber: _phoneController.text.trim(),
            verificationCompleted: (PhoneAuthCredential credential) async {
              await auth.signInWithCredential(credential).then((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                      (route) => false,
                );
              });
            },
            verificationFailed: (FirebaseAuthException e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message ?? '인증 실패'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            codeSent: (String verificationId, int? forceResendingToken) {
              setState(() {
                _codeSent = true;
                _verificationId = verificationId;
              });
            },
            codeAutoRetrievalTimeout: (verificationId) {
              _verificationId = verificationId;
            },
          );
        }
      },
      child: const Text("인증번호 보내기"),
    );
  }

  ElevatedButton verifyButton() {
    return ElevatedButton(
      onPressed: () async {
        FirebaseAuth auth = FirebaseAuth.instance;
        try {
          final credential = PhoneAuthProvider.credential(
            verificationId: _verificationId,
            smsCode: _smsCodeController.text.trim(),
          );

          await auth.signInWithCredential(credential).then((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
            );
          });
        } on FirebaseAuthException catch (e) {
          String message = '인증에 실패했습니다. 다시 시도하세요.';
          if (e.code == 'invalid-verification-code') {
            message = '잘못된 인증번호입니다.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알 수 없는 오류가 발생했습니다.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: const Text("로그인"),
    );
  }
}
