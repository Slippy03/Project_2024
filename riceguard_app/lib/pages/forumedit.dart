import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ForumEditPage extends StatefulWidget {
  @override
  _ForumEditPageState createState() => _ForumEditPageState();
}

class _ForumEditPageState extends State<ForumEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;
  String? forumId;
  List<String> _imageUrls = [];
  List<File> _newImages = [];

  Color get _green => const Color(0xFF2E7D32); // CHANGED: โทนเขียวหลัก
  Color get _greenLight => const Color(0xFFE8F5E9); // CHANGED
  Color get _greenBorder => const Color(0xFF66BB6A); // CHANGED

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
          SnackBar(
            content: const Text('Forum ID หายไป'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadForumData() async {
    if (forumId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('forums')
        .doc(forumId)
        .get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('โพสต์นี้ไม่พบในระบบ'),
            backgroundColor: Colors.red.shade400),
      );
      Navigator.pop(context);
      return;
    }

    final data = doc.data()!;
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';

    final imgs = List<String>.from(data['images'] ?? []);
    _imageUrls = imgs.isNotEmpty ? [imgs.first] : []; // CHANGED: เก็บแค่รูปแรก

    setState(() => _loading = false);
  }

  Future<void> _pickImages() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery); // CHANGED: เลือกรูปเดียว
    if (image != null) {
      setState(() {
        _newImages = [File(image.path)]; // CHANGED: เก็บไว้รูปเดียว ทับของเดิม
      });
    }
  }

  Future<void> _removeExistingImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // CHANGED
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 10),
            const Text('ยืนยันการลบรูป'),
          ],
        ),
        content: const Text('ต้องการลบรูปภาพนี้หรือไม่?'),
        actions: [
          TextButton(
            child:
                Text('ยกเลิก', style: TextStyle(color: Colors.grey.shade600)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)), // CHANGED
            ),
            child: const Text('ลบ'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseStorage.instance.refFromURL(_imageUrls[index]).delete();
        setState(() {
          _imageUrls.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ลบรูปภาพเรียบร้อยแล้ว'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบรูปภาพล้มเหลว: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _deleteStorageFolder(String folderPath) async {
    final folderRef = FirebaseStorage.instance.ref().child(folderPath);

    try {
      final listResult = await folderRef.listAll();

      for (var item in listResult.items) {
        await item.delete();
        // print('ลบไฟล์: ${item.fullPath}');
      }

      for (var prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix.fullPath);
      }

      // print('✅ ลบโฟลเดอร์สำเร็จ: $folderPath');
    } catch (e) {
      // print('❌ ลบโฟลเดอร์ล้มเหลว: $e');
    }
  }

  Future<void> _deleteForum() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text(
            'ต้องการลบโพสต์นี้รวมถึงไฟล์ทั้งหมดหรือไม่?\n\n⚠️ การดำเนินการนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            child:
                Text('ยกเลิก', style: TextStyle(color: Colors.grey.shade600)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ลบทิ้ง'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true && forumId != null) {
      setState(() => _loading = true);

      await _deleteStorageFolder('forums/$forumId');
      await FirebaseFirestore.instance
          .collection('forums')
          .doc(forumId)
          .delete();

      // แสดงยืนยันก่อน แล้วค่อยนำทาง
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ลบโพสต์เรียบร้อยแล้ว'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(milliseconds: 600),
          ),
        );
      }

      await Future.delayed(const Duration(
          milliseconds: 300)); // CHANGED: เว้นจังหวะให้ SnackBar โชว์ทัน

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/forum', (route) => false); // CHANGED: เด้งไปหน้า /forum
    }
  }

  Future<void> _saveForum() async {
    if (!_formKey.currentState!.validate()) return;
    if (forumId == null) return;

    setState(() => _uploading = true);

    try {
      // 1) ลบรูปเดิมออกจาก Storage (ถ้ามี)
      if (_imageUrls.isNotEmpty && _imageUrls.first.isNotEmpty) {
        // CHANGED
        try {
          await FirebaseStorage.instance.refFromURL(_imageUrls.first).delete();
        } catch (_) {
          // ถ้าลบไม่สำเร็จ (เช่น URL เก่า/สิทธิ์) ให้ข้ามไป เพื่อไม่บล็อกการบันทึก
        }
      }

      // 2) อัปโหลดรูปใหม่ (ถ้ามีเลือก)
      String? newUrl;
      if (_newImages.isNotEmpty) {
        // CHANGED: ใช้รูปแรกเท่านั้น
        final imageFile = _newImages.first;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final ref =
            FirebaseStorage.instance.ref().child('forums/$forumId/$fileName');
        await ref.putFile(imageFile);
        newUrl = await ref.getDownloadURL();
      }

      // 3) อัปเดต Firestore ให้ images และ imageUrl ให้สอดคล้อง (รองรับ forumview)
// - ถ้ามีรูปใหม่: ตั้งทั้ง images=[newUrl] และ imageUrl=newUrl
// - ถ้าไม่มีรูป: ตั้ง images=[] และ imageUrl='' (ค่าว่าง)
      final updateData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (newUrl != null) {
        updateData['images'] = [newUrl];
        updateData['imageUrl'] = newUrl; // sync กับ forumview
      } else {
        updateData['images'] = <String>[];
        updateData['imageUrl'] = ''; // เคลียร์รูปเก่าให้ forumview
      }
      await FirebaseFirestore.instance
          .collection('forums')
          .doc(forumId)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('แก้ไขโพสต์เรียบร้อยแล้ว'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red.shade400),
      );
    } finally {
      setState(() => _uploading = false);
    }
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
      backgroundColor: _greenLight, // CHANGED: พื้นหลังเขียวอ่อน
      appBar: AppBar(
        title: const Text('แก้ไขโพสต์',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true, // CHANGED
        // CHANGED: ไล่เฉดสีเขียว
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_green, const Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ลบโพสต์นี้',
            icon: Icon(
              Icons.delete_outline,
              color: const Color.fromARGB(
                  255, 214, 98, 90), // CHANGED: ไอคอนลบเป็นสีแดง
              size: 26,
            ),
            onPressed: _uploading ? null : _deleteForum,
          ),
          if (_uploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _green),
                  const SizedBox(height: 16),
                  Text('กำลังโหลดข้อมูล...',
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Card(
                        elevation: 2,
                        color: Colors.white, // CHANGED
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)), // CHANGED
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit_note,
                                      color: _green, size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    'แก้ไขเนื้อหา',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'หัวข้อ',
                                  hintText: 'ระบุหัวข้อโพสต์',
                                  prefixIcon: Icon(Icons.title, color: _green),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: _green, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: _greenLight,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'กรุณากรอกหัวข้อ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  labelText: 'เนื้อหา',
                                  hintText: 'เขียนเนื้อหาโพสต์ของคุณ...',
                                  prefixIcon:
                                      Icon(Icons.description, color: _green),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: _green, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: _greenLight,
                                ),
                                maxLines: 8,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'กรุณากรอกเนื้อหา';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Section
                      Card(
                        elevation: 2,
                        color: Colors.white, // CHANGED
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)), // CHANGED
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.image, color: _green, size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    'รูปภาพ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // ภาพปัจจุบัน (อย่างมาก 1 รูป)
                              if (_imageUrls.isNotEmpty) ...[
                                Text('รูปภาพปัจจุบัน',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700)),
                                const SizedBox(height: 10),
                                AspectRatio(
                                  aspectRatio:
                                      1, // CHANGED: ช่องสี่เหลี่ยมจัตุรัส
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.green.shade300,
                                              width: 1.6),
                                          image: DecorationImage(
                                            image:
                                                NetworkImage(_imageUrls.first),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: InkWell(
                                          onTap: () => _removeExistingImage(0),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

// รูปใหม่ (อย่างมาก 1 รูป)
                              if (_newImages.isNotEmpty) ...[
                                Text('รูปภาพใหม่',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700)),
                                const SizedBox(height: 10),
                                AspectRatio(
                                  aspectRatio: 1, // CHANGED
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.blue.shade300,
                                              width: 1.6),
                                          image: DecorationImage(
                                            image: FileImage(_newImages.first),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: InkWell(
                                          onTap: () => _removeNewImage(0),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.green.shade700,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: const Text('ใหม่',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 22,
                                  color: Color(0xFF2E7D32), // เขียวเข้ม
                                ),
                                label: const Text(
                                  'เพิ่มรูปภาพ',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFF66BB6A), width: 1.6),
                                  backgroundColor:
                                      const Color(0xFFE8F5E9), // เขียวอ่อนละมุน
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shadowColor: Colors.green.withOpacity(0.15),
                                  elevation: 2, // เพิ่มเงาเล็กน้อย
                                ).copyWith(
                                  overlayColor: MaterialStateProperty.all(
                                    const Color(0xFF66BB6A).withOpacity(0.1),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CHANGED: ย้าย "บันทึก" ลงมาด้านล่างแทนปุ่มลบเดิม
                      ElevatedButton.icon(
                        onPressed: _uploading ? null : _saveForum,
                        icon: const Icon(Icons.check_circle_outline, size: 24),
                        label: const Text('บันทึกการแก้ไข',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),

                      const SizedBox(height: 8),
                      // ปุ่มรอง: ยกเลิก/กลับ
                      TextButton(
                        onPressed:
                            _uploading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ยกเลิกและกลับ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
