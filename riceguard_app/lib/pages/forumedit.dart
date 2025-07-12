import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ForumEditPage extends StatefulWidget {
  @override
  _ForumEditPageState createState() => _ForumEditPageState();
}

class _ForumEditPageState extends State<ForumEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _loading = true;
  String? forumId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (forumId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String && args.isNotEmpty) {
        forumId = args;
        _loadForumData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forum ID หายไป')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadForumData() async {
    if (forumId == null) return;

    final doc = await FirebaseFirestore.instance.collection('forums').doc(forumId).get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โพสต์นี้ไม่พบในระบบ')),
      );
      Navigator.pop(context);
      return;
    }

    final data = doc.data()!;
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';

    setState(() {
      _loading = false;
    });
  }

  Future<void> _deleteStorageFolder(String folderPath) async {
    final folderRef = FirebaseStorage.instance.ref().child(folderPath);

    try {
      final listResult = await folderRef.listAll();

      // 🔥 ลบไฟล์ในโฟลเดอร์
      for (var item in listResult.items) {
        await item.delete();
        print('ลบไฟล์: ${item.fullPath}');
      }

      // 🔥 ลบ subfolders (ถ้ามี)
      for (var prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix.fullPath);
      }

      print('✅ ลบโฟลเดอร์สำเร็จ: $folderPath');
    } catch (e) {
      print('❌ ลบโฟลเดอร์ล้มเหลว: $e');
    }
  }

  Future<void> _deleteForum() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('ต้องการลบโพสต์นี้รวมถึงไฟล์ทั้งหมดหรือไม่?'),
        actions: [
          TextButton(
            child: Text('ยกเลิก'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true && forumId != null) {
      // ✅ ลบไฟล์ทั้งหมดใน Storage
      await _deleteStorageFolder('forums/$forumId');

      // ✅ ลบเอกสารใน Firestore
      await FirebaseFirestore.instance.collection('forums').doc(forumId).delete();

      Navigator.of(context).pushNamedAndRemoveUntil('/mainscreen', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบโพสต์เรียบร้อยแล้ว')),
      );
    }
  }

  Future<void> _saveForum() async {
    if (!_formKey.currentState!.validate()) return;
    if (forumId == null) return;

    await FirebaseFirestore.instance.collection('forums').doc(forumId).update({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('แก้ไขโพสต์เรียบร้อยแล้ว')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขโพสต์'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForum,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'หัวข้อ'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกหัวข้อ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(labelText: 'เนื้อหา'),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกเนื้อหา';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _deleteForum,
                      icon: Icon(Icons.delete),
                      label: Text('ลบโพสต์'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
