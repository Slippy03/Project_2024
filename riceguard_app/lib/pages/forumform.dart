import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navbar.dart';

class ForumFormPage extends StatefulWidget {
  @override
  _ForumFormPageState createState() => _ForumFormPageState();
}

class _ForumFormPageState extends State<ForumFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Function to fetch username from Firestore 'users' collection
  Future<String> _getUsername(String uid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists && userDoc['username'] != null) {
      return userDoc['username']; // Assuming 'username' field exists in 'users' collection
    } else {
      return 'Anonymous'; // Default if no username is found
    }
  }

  Future<void> _createForum() async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;

    if (_formKey.currentState!.validate() && user != null) {
      // Fetch username from Firestore 'users' collection
      String username = await _getUsername(user.uid);

      // Create a new document with a unique ID
      DocumentReference forumRef = FirebaseFirestore.instance.collection('forums').doc();

      await forumRef.set({
        'id': forumRef.id, // Add the unique forum ID here
        'title': _titleController.text,
        'content': _contentController.text,
        'username': username, // Add the fetched username here
        'timestamp': Timestamp.now(),
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Forum'),
        backgroundColor: Color.fromRGBO(134, 245, 137, 1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'หัวข้อกระทู้'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'กรุณากรอกหัวข้อกระทู้';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'เนื้อหาของกระทู้'),
                maxLines: 5,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'กรุณากรอกเนื้อหาของกระทู้'; 
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _createForum,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                ),
                child: Text('สร้างกระทู้'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
