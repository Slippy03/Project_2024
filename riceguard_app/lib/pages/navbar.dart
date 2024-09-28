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
          label: 'Forum',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: 'Camera',
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
      onTap: (index) {
        if (index == 4) {  
          _showLogoutDialog(context);
        } else {
          
          switch (index) {
            case 0: 
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1: 
              Navigator.of(context).pushReplacementNamed('/forum');
              break;
            case 2: 
           
              break;
            case 3: 
              Navigator.of(context).pushReplacementNamed('/profile');
              break;
          }
          onTap(index);  
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
          content: Text('ต้องการออกจากระบบใช่หรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: Text('ไม่'),
              onPressed: () {
                Navigator.of(context).pop();  
              },
            ),
            TextButton(
              child: Text('ใช่'),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');  
              },
            ),
          ],
        );
      },
    );
  }
}
