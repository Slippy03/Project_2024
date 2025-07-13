import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:riceguard_app/firebase_options.dart';
import 'package:riceguard_app/pages/forum.dart';
import 'package:riceguard_app/pages/history.dart';
import 'package:riceguard_app/pages/forumview.dart';
import 'package:riceguard_app/pages/navbar.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/forumform.dart';
import 'pages/profile.dart';
import 'pages/PredictScreeen.dart';
import 'pages/GoogleMapPage.dart';
import 'pages/mainscreen.dart';
import 'pages/forumedit.dart';
import 'pages/info.dart';

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

      home:LoginPage(), 

      routes: {
        '/login': (context) => LoginPage(),
        '/forumview': (context) => ForumViewPage(),
        '/forumform': (context) => ForumFormPage(),
        '/profile': (context) => ProfilePage(),
        '/googlemap': (context) => GoogleMapPage(),
        '/history': (context) => HistoryPage(),
        '/forumedit': (context) => ForumEditPage(),
        '/mainscreen' : (context) => MainScreen(),
        '/forum':(context)=> ForumPage()
        '/info': (context) => infopage(),
        '/camera': (context) => PredictScreeen(),
        '/map_from_forum': (context) {
          final pinId = ModalRoute.of(context)?.settings.arguments as String?;
          return GoogleMapPage(initialPinId: pinId);
        },
      },)
  }
}
