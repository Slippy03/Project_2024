import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Function(int) onMenuTap;

  const HomePage({required this.onMenuTap});

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
                Navigator.of(context).pushNamed('/camera');
              },
            ),
            _buildMenuItem(
              context,
              'ระบบ Forum สำหรับแลกเปลี่ยนข้อมูล',
              'assets/images/mail-box.png',
              () {
                 {
                Navigator.of(context).pushNamed('/forum'); 
              }
              },
            ),
            _buildMenuItem(
              context,
              'องค์ความรู้โรคข้าว',
              'assets/images/virus.png',
              () {
                 Navigator.of(context).pushNamed('/info');
              },
            ),
            _buildMenuItem(
              context,
              'สำรวจบริเวณที่เกิดโรค',
              'assets/images/maps.png',
              () {
                {
                Navigator.of(context).pushNamed('/googlemap'); 
              }
              },
            ),
            _buildMenuItem(
              context,
              'ประวัติการรักษาโรค',
              'assets/images/document.png',
              () {
                {
                Navigator.of(context).pushNamed('/history');
              }
              },
            ),
          ],
        ),
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
