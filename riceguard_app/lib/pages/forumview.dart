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
  bool _isFollowing = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String id, User currentUser) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String filePath = 'forums/$id/comments/${currentUser.uid}_$timestamp.jpg';
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(filePath).putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _postComment(String id) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _commentController.text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final username = userDoc.exists ? userDoc['username'] : 'Anonymous';

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!, id, currentUser);
    }

    await FirebaseFirestore.instance
        .collection('forums')
        .doc(id)
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

  Future<void> _toggleFollow(String id) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final followerRef = FirebaseFirestore.instance
        .collection('forums')
        .doc(id)
        .collection('follower')
        .doc(currentUser.uid);

    final doc = await followerRef.get();
    if (doc.exists) {
      await followerRef.delete();
      setState(() {
        _isFollowing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เลิกติดตามกระทู้แล้ว'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await followerRef.set({
        'uid': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isFollowing = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ติดตามกระทู้เรียบร้อย'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _checkFollowing(String id) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('forums')
        .doc(id)
        .collection('follower')
        .doc(currentUser.uid)
        .get();

    setState(() {
      _isFollowing = doc.exists;
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
    final String id = args;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('forums').doc(id).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text("Forum Details")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final forumDoc = snapshot.data!;
        final data = forumDoc.data() as Map<String, dynamic>;
        final hasPin = data.containsKey('pinId') &&
            (data['pinId']?.toString().isNotEmpty ?? false);
        final ownerId = data['uid'];

        if (FirebaseAuth.instance.currentUser?.uid != ownerId) {
          _checkFollowing(id);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Forum Details'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              if (FirebaseAuth.instance.currentUser?.uid != ownerId)
                IconButton(
                  icon: Icon(
                    _isFollowing ? Icons.favorite : Icons.favorite_border,
                    color: _isFollowing ? Colors.red : Colors.white,
                  ),
                  onPressed: () => _toggleFollow(id),
                ),
              if (FirebaseAuth.instance.currentUser?.uid == ownerId)
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/forumedit',
                      arguments: id,
                    );
                  },
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                ),
                SizedBox(height: 16),
                Text(data['content'] ?? '', style: TextStyle(fontSize: 16)),
                
                if ((data['imageUrl'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Image.network(
                      data['imageUrl'],
                      fit: BoxFit.cover,
                    ),
                  ),

                SizedBox(height: 16),
                Text('โดย ${data['username'] ?? 'Unknown'}', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                        .doc(id)
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
                      onPressed: () => _postComment(id),
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
          ),
        );
      },
    );
  }
}
