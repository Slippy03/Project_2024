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

  Future<String?> _uploadImage(
      File imageFile, String forumId, User currentUser) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String filePath =
          'forums/$forumId/comments/${currentUser.uid}_$timestamp.jpg';
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref(filePath).putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _postComment(String forumId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _commentController.text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final username = userDoc.exists ? userDoc['username'] : 'Anonymous';

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!, forumId, currentUser);
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
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! String || args.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Forum Details")),
        body: Center(child: Text("Forum ID is missing")),
      );
    }
    final String forumId = args;

    return Scaffold(
      appBar: AppBar(
        title: Text('Forum Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('forums').doc(forumId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final forumDoc = snapshot.data!;
          final data = forumDoc.data() as Map<String, dynamic>;
          final hasPin = data.containsKey('pinId') &&
              (data['pinId']?.toString().isNotEmpty ?? false);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreen),
                ),
                SizedBox(height: 16),
                Text(data['content'] ?? '', style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text('โดย ${data['username'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (hasPin)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/map_from_forum',
                          arguments: data['pinId'],
                        );
                      },
                      icon: Icon(Icons.location_pin),
                      label: Text("ดูตำแหน่งบนแผนที่"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
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
                            title: Text(comment['username'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['content'] ?? ''),
                                if ((comment['imageUrl'] ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Image.network(comment['imageUrl']),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              comment['timestamp']?.toDate().toString() ?? '',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
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
                        decoration:
                            InputDecoration(hintText: 'Add a comment...'),
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