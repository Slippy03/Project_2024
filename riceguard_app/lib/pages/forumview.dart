import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

class ForumViewPage extends StatefulWidget {
  @override
  _ForumViewPageState createState() => _ForumViewPageState();
}

class _ForumViewPageState extends State<ForumViewPage> {
  // --- BEGIN: image URL resolver (supports both `imageUrl` and `images[0]`) ---
  String? _resolveImageUrlFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final dynamic single = data['imageUrl'];
    if (single is String && single.trim().isNotEmpty) return single.trim();
    final dynamic images = data['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
    }
    return null;
  }

  String? _resolveImageUrlFromDynamic(dynamic v) {
    if (v is Map<String, dynamic>) {
      return _resolveImageUrlFromMap(v);
    }
    // If comment is a DocumentSnapshot-like map
    if (v is Map) {
      try {
        final map = Map<String, dynamic>.from(v as Map);
        return _resolveImageUrlFromMap(map);
      } catch (_) {}
    }
    return null;
  }
  // --- END: image URL resolver ---

  final TextEditingController _commentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isFollowing = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('th', null);
    setState(() {
      _localeInitialized = true;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(
      File imageFile, String id, User currentUser) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String filePath = 'forums/$id/comments/${currentUser.uid}_$timestamp.jpg';
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref(filePath).putFile(imageFile);
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
          content: Row(
            children: [
              Icon(Icons.bookmark_remove, color: Colors.white),
              SizedBox(width: 8),
              Text('เลิกติดตามกระทู้แล้ว'),
            ],
          ),
          backgroundColor: Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          content: Row(
            children: [
              Icon(Icons.bookmark_added, color: Colors.white),
              SizedBox(width: 8),
              Text('ติดตามกระทู้เรียบร้อย'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        appBar: AppBar(
          title: Text("รายละเอียดกระทู้"),
          backgroundColor: Color(0xFF4CAF50),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "ไม่พบข้อมูลกระทู้",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    final String id = args;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forums')
          .doc(id)
          .snapshots(), // FIX: real-time
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text("รายละเอียดกระทู้"),
              backgroundColor: Color(0xFF4CAF50),
            ),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          );
        }

        if (!snapshot.data!.exists) {
          // กระทู้ถูกลบไปแล้ว
          return Scaffold(
            appBar: AppBar(
              title: Text("รายละเอียดกระทู้"),
              backgroundColor: Color(0xFF4CAF50),
            ),
            body: Center(child: Text("กระทู้นี้ถูกลบแล้ว")),
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
            elevation: 0,
            title: Text(
              'รายละเอียดกระทู้',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF66BB6A),
                  ],
                ),
              ),
            ),
            actions: [
              if (FirebaseAuth.instance.currentUser?.uid != ownerId)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _isFollowing
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => _toggleFollow(id),
                  ),
                ),
              if (FirebaseAuth.instance.currentUser?.uid == ownerId)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(Icons.edit, size: 26),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/forumedit',
                        arguments: id,
                      );
                    },
                  ),
                ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFC8E6C9),
                  Colors.white,
                ],
                stops: [0.0, 0.3],
              ),
            ),
            child: Column(
              children: [
                // Forum Content Card
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Main Forum Post
                        Container(
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  data['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Content
                                Text(
                                  data['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),

                                // Image (if exists)
                                if (_resolveImageUrlFromMap(data) != null)
                                  Container(
                                    margin: EdgeInsets.only(top: 16),
                                    constraints: BoxConstraints(
                                      maxHeight: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _resolveImageUrlFromMap(data)!,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 200,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color(0xFF4CAF50),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 16),
                                Divider(),

                                // Author and Location
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Color(0xFF81C784),
                                          radius: 16,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'โดย ${data['username'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasPin)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/map_from_forum',
                                            arguments: data['pinId'],
                                          );
                                        },
                                        icon: Icon(Icons.location_on, size: 18),
                                        label: Text("ดูตำแหน่ง"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF4CAF50),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Comments Section
                        Container(
                          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.comment,
                                      color: Color(0xFF4CAF50),
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'ความคิดเห็น',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1),
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: 400,
                                ),
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('forums')
                                      .doc(id)
                                      .collection('comments')
                                      .orderBy('timestamp', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        height: 100,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Color(0xFF4CAF50),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final comments = snapshot.data!.docs;

                                    if (comments.isEmpty) {
                                      return Container(
                                        padding: EdgeInsets.all(32),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.chat_bubble_outline,
                                                size: 48,
                                                color: Colors.grey[300],
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'ยังไม่มีความคิดเห็น',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.all(16),
                                      itemCount: comments.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(height: 24),
                                      itemBuilder: (context, index) {
                                        final comment = comments[index];
                                        final timestamp = comment['timestamp'];
                                        String timeString = '';

                                        if (timestamp != null &&
                                            _localeInitialized) {
                                          try {
                                            timeString = DateFormat(
                                                    'd MMM yyyy, HH:mm', 'th')
                                                .format(timestamp.toDate());
                                          } catch (e) {
                                            timeString = '';
                                          }
                                        }

                                        return Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF1F8E9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Username and timestamp
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor:
                                                            Color(0xFF81C784),
                                                        radius: 14,
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        comment['username'] ??
                                                            'Anonymous',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xFF2E7D32),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (timeString.isNotEmpty)
                                                    Text(
                                                      timeString,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 8),

                                              // Comment content
                                              Text(
                                                comment['content'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),

                                              // Comment image
                                              if (_resolveImageUrlFromDynamic(
                                                      comment) !=
                                                  null)
                                                Container(
                                                  margin:
                                                      EdgeInsets.only(top: 12),
                                                  constraints: BoxConstraints(
                                                    maxHeight: 200,
                                                    maxWidth: 250,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      _resolveImageUrlFromDynamic(
                                                          comment)!,
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Container(
                                                          height: 150,
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(
                                                                Color(
                                                                    0xFF4CAF50),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment Input Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_imageFile != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _imageFile = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon:
                                    Icon(Icons.image, color: Color(0xFF4CAF50)),
                                onPressed: _pickImage,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: 'เขียนความคิดเห็น...',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: null,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF66BB6A),
                                    Color(0xFF4CAF50),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: () => _postComment(id),
                              ),
                            ),
                          ],
                        ),
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
