import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumPage extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  String searchQuery = '';
  String dateFilter = 'ทั้งหมด';
  bool showMyPosts = false;

  DateTime? _getFilterDate() {
    final now = DateTime.now();
    switch (dateFilter) {
      case 'วันนี้':
        return DateTime(now.year, now.month, now.day);
      case 'สัปดาห์นี้':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'เดือนนี้':
        return DateTime(now.year, now.month, 1);
      case 'ปีนี้':
        return DateTime(now.year, 1, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? filterDate = _getFilterDate();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('FORUM'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              showMyPosts ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: 'กระทู้ของฉัน',
            onPressed: () {
              setState(() {
                showMyPosts = !showMyPosts;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาหัวข้อกระทู้...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.filter_list, color: Colors.white),
                    onSelected: (value) {
                      setState(() {
                        dateFilter = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                      PopupMenuItem(value: 'วันนี้', child: Text('วันนี้')),
                      PopupMenuItem(value: 'สัปดาห์นี้', child: Text('สัปดาห์นี้')),
                      PopupMenuItem(value: 'เดือนนี้', child: Text('เดือนนี้')),
                      PopupMenuItem(value: 'ปีนี้', child: Text('ปีนี้')),
                    ],
                  )
                ],
              ),
            ),

            // Forum list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('forums')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final forums = snapshot.data!.docs.where((forum) {
                    final title = forum['title'].toString().toLowerCase();
                    final timestamp = forum['timestamp'] as Timestamp;
                    final postDate = timestamp.toDate();

                    final matchSearch = title.contains(searchQuery);
                    final matchDate = filterDate == null || postDate.isAfter(filterDate);

                    return matchSearch && matchDate;
                  }).toList();

                  if (forums.isEmpty) {
                    return Center(child: Text('ไม่พบหัวข้อกระทู้'));
                  }

                  return ListView.builder(
                    itemCount: forums.length,
                    itemBuilder: (context, index) {
                      var forum = forums[index];
                      final forumId = forum.id;

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('forums')
                            .doc(forumId)
                            .collection('follower')
                            .where(FieldPath.documentId, isEqualTo: currentUser?.uid)
                            .get(),
                        builder: (context, followerSnapshot) {
                          if (!followerSnapshot.hasData) {
                            return SizedBox(
                              height: 80,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final isFollower = followerSnapshot.data!.docs.isNotEmpty;
                          final isOwner = forum['uid'] == currentUser?.uid;

                          // กรองตาม showMyPosts
                          if (showMyPosts && !(isOwner || isFollower)) {
                            return SizedBox.shrink(); 
                          }

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
                                subtitle: Text(
                                  DateFormat.yMMMd().add_Hm().format(
                                      (forum['timestamp'] as Timestamp).toDate()),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/forumview',
                                    arguments: forum.id,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/forumform');
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}
