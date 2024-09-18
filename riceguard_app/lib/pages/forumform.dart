import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navbar.dart';

class ForumFormPage extends StatefulWidget {
  @override
  _ForumFormPageState createState() => _ForumFormPageState();
}

class _ForumFormPageState extends State<ForumFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _createForum() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('forums').add({
        'title': _titleController.text,
        'content': _contentController.text,
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
                  primary: Colors.green, // Background color
                  onPrimary: Colors.white, // Text color
                ),
                child: Text('สร้างกระทู้'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MyBottomNavBar(currentIndex: 1, onTap: (index) {}),
    );
  }
}
