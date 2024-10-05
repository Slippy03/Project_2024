import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String? currentUsername;

  @override
  void initState() {
    super.initState();
    currentUsername = widget.userData['username'];
    _usernameController = TextEditingController(text: currentUsername);
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        String newUsername = _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : currentUsername!;
        String newName = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : widget.userData['name'];
        String newPhone = _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : widget.userData['phone'];

        
        if (newUsername != currentUsername) {
          bool isUnique = await _isUsernameUnique(newUsername);
          if (!isUnique) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ชื่อผู้ใช้นี้ถูกใช้แล้ว')),
            );
            return; 
          }
        }

        
        await _firestore.collection('users').doc(currentUser.uid).update({
          'username': newUsername,
          'name': newName,
          'phone': newPhone,
        });

        
        Navigator.pop(context, {
          'username': newUsername,
          'name': newName,
          'phone': newPhone,
        });
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<bool> _isUsernameUnique(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isEmpty; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(color: Colors.white), 
        ),
        backgroundColor: Colors.green, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_usernameController, 'ชื่อผู้ใช้', currentUsername),
            SizedBox(height: 16), 
            _buildTextField(_nameController, 'ชื่อ', widget.userData['name']),
            SizedBox(height: 16), 
            _buildTextField(_phoneController, 'เบอร์โทรศัพท์', widget.userData['phone'], isPhone: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('บันทึกการแก้ไข'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String? currentValue, {bool isPhone = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: currentValue, 
        hintStyle: TextStyle(color: Colors.grey), 
        border: OutlineInputBorder(),
        filled: true, 
        fillColor: Colors.white, 
      ),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      onTap: () {
        
        if (controller.text == currentValue) {
          controller.clear();
        }
      },
    );
  }
}
