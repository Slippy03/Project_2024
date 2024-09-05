import 'package:flutter/material.dart';
import 'pages/login.dart';

void main() {
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
