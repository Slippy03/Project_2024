import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navbar.dart';

class ForumPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FORUM'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('forums').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final forums = snapshot.data!.docs;
            return ListView.builder(
              itemCount: forums.length,
              itemBuilder: (context, index) {
                var forum = forums[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      title: Text(
                        forum['title'],
                        style: TextStyle(
                          color: Colors.lightGreen, 
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/forumview',
                          arguments: forum.id, // ส่ง forum ID หรือข้อมูลที่ต้องการ
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/forumform');
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2),
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forumform');
                  },
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.add),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavBar(currentIndex: 1, onTap: (index) {}),
    );
  }
}
