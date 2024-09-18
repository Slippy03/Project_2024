import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:riceguard_app/firebase_options.dart';
import 'pages/login.dart';
import 'pages/home.dart';

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
      title: 'RiceGuard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',  // หน้าเริ่มต้นเป็นหน้า home
      routes: {
        '/login': (context) => LoginPage(),  // เส้นทางสำหรับหน้า login
        '/home': (context) => HomePage(),  // เส้นทางสำหรับหน้า home
      },
    );
  }
}

