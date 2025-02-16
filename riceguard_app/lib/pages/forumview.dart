import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumViewPage extends StatelessWidget {
  final TextEditingController _commentController = TextEditingController();

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
                  forumData['content'],
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'โดย ${forumData['username']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Divider(height: 32, color: Colors.grey),
                // Comment Section
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('forums')
                        .doc(forumId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            title: Text(comment['username']),
                            subtitle: Text(comment['content']),
                            trailing: Text(
                              comment['timestamp']?.toDate().toString() ?? '',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Add Comment Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(hintText: 'Add a comment...'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.green),
                      onPressed: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (_commentController.text.isNotEmpty && currentUser != null) {
                          await FirebaseFirestore.instance
                              .collection('forums')
                              .doc(forumId)
                              .collection('comments')
                              .add({
                            'username': currentUser.displayName ?? 'Anonymous',
                            'content': _commentController.text,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          _commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
