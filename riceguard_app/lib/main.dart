import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:riceguard_app/firebase_options.dart';
import 'pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // ทำให้แน่ใจว่า Flutter ถูกเริ่มต้นก่อน
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(RiceGuardApp());
}

class RiceGuardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
