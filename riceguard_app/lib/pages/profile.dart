import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users') // Assuming user data is stored in 'users' collection
            .doc(currentUser!.uid)
            .get();

        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(userData!['profileImageUrl'] ?? 'https://via.placeholder.com/150'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userData!['username'] ?? 'Unknown Username',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userData!['name'] ?? 'Unknown Name',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    currentUser!.email ?? 'Unknown Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildUserInfo('Phone Number', userData!['phoneNumber']),
                ],
              ),
            ),
    );
  }

  // Build individual user info rows
  Widget _buildUserInfo(String title, String? info) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            info ?? 'N/A',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
