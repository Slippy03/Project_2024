import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:riceguard_app/pages/forumview.dart'; 
import 'package:riceguard_app/firebase_options.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/forum.dart';
import 'pages/forumform.dart';    
import 'pages/profile.dart';      
import 'pages/PredictScreeen.dart';
import 'pages/GoogleMapPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  await Firebase.initializeApp(               
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
      
      initialRoute: '/login', 
      routes: {
        '/login': (context) => LoginPage(),     
        '/home': (context) => HomePage(),       
        '/forum': (context) => ForumPage(),  
        '/camera': (context) => PredictScreeen(),   
        '/forumform': (context) => ForumFormPage(), 
        '/forumview': (context) => ForumViewPage(), 
        '/profile': (context) => ProfilePage(),
        '/googlemap':(context) => GoogleMapPage(),
      },
    );
  }
}
