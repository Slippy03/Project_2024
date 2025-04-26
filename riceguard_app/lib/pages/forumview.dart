import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ForumViewPage extends StatefulWidget {
  @override
  _ForumViewPageState createState() => _ForumViewPageState();
}

class _ForumViewPageState extends State<ForumViewPage> {
  final TextEditingController _commentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = 'comments/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref(fileName)
          .putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _postComment(String forumId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _commentController.text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final username = userDoc.exists ? userDoc['username'] : 'Anonymous';

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    await FirebaseFirestore.instance
        .collection('forums')
        .doc(forumId)
        .collection('comments')
        .add({
      'username': username,
      'content': _commentController.text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    setState(() {
      _imageFile = null;
    });
  }

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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['content']),
                                if (comment['imageUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Image.network(comment['imageUrl']),
                                  ),
                              ],
                            ),
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image, color: Colors.green),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(hintText: 'Add a comment...'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.green),
                      onPressed: () => _postComment(forumId),
                    ),
                  ],
                ),
                if (_imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(_imageFile!, height: 100),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _imageFile = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
