import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String forumId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Forum Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('forums').doc(forumId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final forumData = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forumData['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                ),
                SizedBox(height: 16),
                Text(
                  forumData['content'], // สมมติว่า forum มี field ชื่อ content
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                // ข้อความเกี่ยวกับผู้สร้าง
                Text(
                  'โดย ${forumData['username']}', // สมมติว่ามีฟิลด์ creator
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
