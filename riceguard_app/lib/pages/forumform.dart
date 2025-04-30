import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumFormPage extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? pinId; // ✅ เพิ่ม pinId

  const ForumFormPage({
    this.initialTitle,
    this.initialContent,
    this.pinId, // ✅ รองรับ pinId
    Key? key,
  }) : super(key: key);

  @override
  _ForumFormPageState createState() => _ForumFormPageState();
}

class _ForumFormPageState extends State<ForumFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ดึงชื่อผู้ใช้จาก Firestore
  Future<String> _getUsername(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc['username'] != null) {
        return userDoc['username'];
      } else {
        return 'Anonymous';
      }
    } catch (e) {
      print('Error fetching username: $e');
      return 'Anonymous';
    }
  }

  Future<void> _createForum() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (_formKey.currentState!.validate() && user != null) {
      String username = await _getUsername(user.uid);

      DocumentReference forumRef =
          FirebaseFirestore.instance.collection('forums').doc();

      await forumRef.set({
        'id': forumRef.id,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'username': username,
        'timestamp': Timestamp.now(),
        'uid': user.uid,
        if (widget.pinId != null && widget.pinId!.isNotEmpty)
          'pinId': widget.pinId, // ✅ เก็บ pinId ถ้ามี
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Forum created successfully!")),
      );

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
              if (widget.pinId != null) // ✅ แสดงข้อความว่าอิงจาก Pin
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.green),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "โพสต์นี้เชื่อมกับตำแหน่งบนแผนที่ (Pin ID: ${widget.pinId})",
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'หัวข้อกระทู้'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเนื้อหาของกระทู้';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: _createForum,
                icon: Icon(Icons.send),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
                label: Text('สร้างกระทู้'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
