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
import 'pages/forumedit.dart';

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
        '/info': (context) => infopage(),
        '/forumedit': (context) => ForumEditPage(),
        '/home': (context) => HomePage(),
        '/forum': (context) => ForumPage(),
        '/camera': (context) => PredictScreeen(),
        '/forumform': (context) => ForumFormPage(),
        '/forumview': (context) => ForumViewPage(),
        '/profile': (context) => ProfilePage(),
        '/googlemap': (context) => GoogleMapPage(),
        '/history': (context) => HistoryPage(),
        '/map_from_forum': (context) {
          final pinId = ModalRoute.of(context)?.settings.arguments as String?;
          return GoogleMapPage(initialPinId: pinId);
        },
      },
    );
  }
}
