import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  MyBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home', 
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum),
          label: 'Notification',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 3) {  
          _showLogoutDialog(context);
        } else {
          onTap(index); // อัปเดต index แทนการใช้ Navigator
        }
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('ต้องการออกจากระบบใช่หรือไม่ ?'),
          actions: <Widget>[
            TextButton(
              child: Text('ไม่'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('ใช่'),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();  
                Navigator.of(context).pushReplacementNamed('/login');  
              },
            ),
          ],
        );
      },
    );
  }
}
