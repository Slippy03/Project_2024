import 'package:flutter/material.dart';
import 'navbar.dart';  

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;  

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/forum');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RiceGuard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildMenuItem(
              context,
              'ตรวจสอบโรคของข้าวด้วยกล้อง',
              'assets/images/camera.png',
              () {
                // ไปที่หน้ากล้อง
              },
            ),
            _buildMenuItem(
              context,
              'ระบบ Forum สำหรับแลกเปลี่ยนข้อมูล',
              'assets/images/mail-box.png',
              () {
                Navigator.of(context).pushNamed('/forum'); // Navigate to ForumPage
              },
            ),
            _buildMenuItem(
              context,
              'วิธีการรักษาโรคของข้าว',
              'assets/images/cure.png',
              () {
                // ไปที่หน้าการรักษาโรค
              },
            ),
            _buildMenuItem(
              context,
              '5 โรคที่พบบ่อยในข้าว',
              'assets/images/virus.png',
              () {
                // ไปที่หน้าโรคที่พบบ่อย
              },
            ),
            _buildMenuItem(
              context,
              'สำรวจบริเวณที่เกิดโรค',
              'assets/images/maps.png',
              () {
                Navigator.of(context).pushNamed('/googlemap');
              },
            ),
            _buildMenuItem(
              context,
              'การตั้งค่า / Settings',
              'assets/images/settings.png',
              () {
                // ไปที่หน้าการตั้งค่า
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyBottomNavBar(
        currentIndex: _selectedIndex, 
        onTap: _onItemTapped, 
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 60, width: 60),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
