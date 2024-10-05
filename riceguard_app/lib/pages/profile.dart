import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'navbar.dart';
import 'editprofile.dart'; 

class ProfilePage extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? currentUser;
  Map<String, dynamic>? userData;

  int _currentIndex = 3; 

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
            .collection('users') 
            .doc(currentUser!.uid)
            .get();

        setState(() {
          userData = userDoc.data() as Map<String, dynamic>? ?? {};
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
        title: Align(
          alignment: Alignment.centerLeft, 
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white, 
            ),
          ),
        ),
        centerTitle: false, 
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  
                  _buildProfileHeader(),
                  SizedBox(height: 20),
                  
                  _buildPersonalInfo(),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
      
      
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(userData!['profileImageUrl'] ?? 'https://via.placeholder.com/150'),
          ),
          SizedBox(height: 10),
          Text(
            userData!['name'] ?? 'Unknown Name',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Text(
            currentUser!.email ?? 'Unknown Email',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('ข้อมูลส่วนตัว'),
            ),
          ),
          SizedBox(height: 20),
          _buildUserInfo('Username', userData!['username']),
          _buildUserInfo('Name', userData!['name']),
          _buildUserInfo('Email', currentUser!.email),
          _buildUserInfo('Phone Number', userData!['phone']),
          _buildUserInfo(
            'เป็นสมาชิกตั้งแต่',
            _formatTimestamp(userData!['created_at']),
          ),
          
          SizedBox(height: 20), 
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final updatedData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userData: userData!),
                  ),
                );

                
                if (updatedData != null) {
                  setState(() {
                    userData!['username'] = updatedData['username']; 
                    userData!['name'] = updatedData['name']; 
                    userData!['phone'] = updatedData['phone']; 
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('แก้ไขโปรไฟล์'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String title, String? info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              info ?? 'N/A',
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    DateTime date = timestamp.toDate(); 
    return DateFormat('dd / MM / yyyy').format(date); 
  }

  Widget _buildBottomNavBar() {
    return MyBottomNavBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
