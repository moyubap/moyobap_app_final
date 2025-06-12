import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("모여밥")),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                phoneNumberInput(),
                const SizedBox(height: 15),
                _codeSent ? const SizedBox.shrink() : submitButton(),
                const SizedBox(height: 15),
                _codeSent ? smsCodeInput() : const SizedBox.shrink(),
                const SizedBox(height: 15),
                _codeSent ? verifyButton() : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField phoneNumberInput() {
    return TextFormField(
      controller: _phoneController,
      autofocus: true,
      validator: (val) => val == null || val.isEmpty ? '전화번호를 입력하세요.' : null,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '+82 00-0000-0000',
        labelText: '전화번호',
        labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  TextFormField smsCodeInput() {
    return TextFormField(
      controller: _smsCodeController,
      autofocus: true,
      validator: (val) => val == null || val.isEmpty ? '인증번호를 입력하세요.' : null,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '인증번호를 입력해주세요.',
        labelText: '인증번호',
        labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              await auth
                  .signInWithCredential(credential)
                  .then((_) => Navigator.pushReplacementNamed(context, "/main"));
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
            codeSent: (String verificationId, int? forceResendingToken) async {
              setState(() {
                _codeSent = true;
                _verificationId = verificationId;
              });
            },
            codeAutoRetrievalTimeout: (verificationId) {
              _verificationId = verificationId;
              print("Auto retrieval timeout");
            },
          );
        }
      },
      child: const Padding(
        padding: EdgeInsets.all(15),
        child: Text("인증번호 보내기", style: TextStyle(fontSize: 18)),
      ),
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

          await auth.signInWithCredential(credential)
              .then((_) => Navigator.pushReplacementNamed(context, "/main"));
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
      child: const Padding(
        padding: EdgeInsets.all(15),
        child: Text("로그인", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
