import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:riceguard_app/firebase_options.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/forum.dart';        // นำเข้า forum.dart
import 'pages/forumform.dart';    // นำเข้า forumform.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // ทำให้แน่ใจว่า Flutter ถูกเริ่มต้นก่อน
  await Firebase.initializeApp(               // รอการเริ่มต้น Firebase ก่อนทำงานต่อ
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(RiceGuardApp());
}

class RiceGuardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiceGuard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',  // หน้าเริ่มต้นเป็นหน้า login
      routes: {
        '/login': (context) => LoginPage(),     // เส้นทางสำหรับหน้า login
        '/home': (context) => HomePage(),       // เส้นทางสำหรับหน้า home
        '/forum': (context) => ForumPage(),     // เส้นทางสำหรับหน้า forum
        '/forumform': (context) => ForumFormPage(), // เส้นทางสำหรับหน้า forumform
      },
    );
  }
}
