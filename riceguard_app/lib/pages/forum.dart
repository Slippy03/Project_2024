import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumPage extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  String searchQuery = '';
  String dateFilter = 'ทั้งหมด';
  bool showMyPosts = false;
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

  DateTime? _getFilterDate() {
    final now = DateTime.now();
    switch (dateFilter) {
      case 'วันนี้':
        return DateTime(now.year, now.month, now.day);
      case 'สัปดาห์นี้':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'เดือนนี้':
        return DateTime(now.year, now.month, 1);
      case 'ปีนี้':
        return DateTime(now.year, 1, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? filterDate = _getFilterDate();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Show loading while initializing locale
    if (!_localeInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('กระทู้โรคข้าว'),
          backgroundColor: Color(0xFF4CAF50),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context, filterDate, currentUser),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.grass, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Text(
            'กระทู้โรคข้าว',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: showMyPosts
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              showMyPosts ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'กระทู้ของฉัน',
            onPressed: () {
              setState(() {
                showMyPosts = !showMyPosts;
              });
            },
          ),
        ),
      ],
    );
  }

  // ==================== BODY ====================
  Widget _buildBody(
      BuildContext context, DateTime? filterDate, User? currentUser) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81C784), Color(0xFFC8E6C9), Colors.white],
          stops: [0.0, 0.3, 0.7],
        ),
      ),
      child: Column(
        children: [
          _buildSearchAndFilterSection(context),
          Expanded(
            child: _buildForumList(context, filterDate, currentUser),
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH & FILTER SECTION ====================
  Widget _buildSearchAndFilterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: 12),
          _buildFilterChips(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ค้นหาหัวข้อกระทู้...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Color(0xFF4CAF50)),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildFilterChip(
          label: dateFilter,
          icon: Icons.calendar_today,
          onTap: () => _showDateFilterBottomSheet(context),
        ),
        if (showMyPosts) ...[
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'กระทู้ของฉัน',
            icon: Icons.bookmark,
            isActive: true,
            onTap: () {
              setState(() {
                showMyPosts = false;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Color(0xFF4CAF50),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isActive) ...[
              SizedBox(width: 4),
              Icon(Icons.close, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showDateFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'เลือกช่วงเวลา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            ...[
              'ทั้งหมด',
              'วันนี้',
              'สัปดาห์นี้',
              'เดือนนี้',
              'ปีนี้'
            ].map((filter) => ListTile(
                  leading: Icon(
                    Icons.access_time,
                    color:
                        dateFilter == filter ? Color(0xFF4CAF50) : Colors.grey,
                  ),
                  title: Text(
                    filter,
                    style: TextStyle(
                      fontWeight: dateFilter == filter
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: dateFilter == filter
                          ? Color(0xFF2E7D32)
                          : Colors.black87,
                    ),
                  ),
                  trailing: dateFilter == filter
                      ? Icon(Icons.check, color: Color(0xFF4CAF50))
                      : null,
                  onTap: () {
                    setState(() {
                      dateFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================== FORUM LIST ====================
  Widget _buildForumList(
      BuildContext context, DateTime? filterDate, User? currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forums')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        final forums = snapshot.data!.docs.where((forum) {
          final title = forum['title'].toString().toLowerCase();
          final timestamp = forum['timestamp'] as Timestamp;
          final postDate = timestamp.toDate();

          final matchSearch = title.contains(searchQuery);
          final matchDate = filterDate == null || postDate.isAfter(filterDate);

          return matchSearch && matchDate;
        }).toList();

        if (forums.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 80),
          itemCount: forums.length,
          itemBuilder: (context, index) {
            return _buildForumItem(context, forums[index], currentUser);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'ไม่พบหัวข้อกระทู้',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumItem(
      BuildContext context, DocumentSnapshot forum, User? currentUser) {
    final forumId = forum.id;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('forums')
          .doc(forumId)
          .collection('follower')
          .where(FieldPath.documentId, isEqualTo: currentUser?.uid)
          .get(),
      builder: (context, followerSnapshot) {
        if (!followerSnapshot.hasData) {
          return SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          );
        }

        final isFollower = followerSnapshot.data!.docs.isNotEmpty;
        final isOwner = forum['uid'] == currentUser?.uid;

        if (showMyPosts && !(isOwner || isFollower)) {
          return SizedBox.shrink();
        }

        return _buildForumCard(context, forum, isOwner, isFollower);
      },
    );
  }

  Widget _buildForumCard(
    BuildContext context,
    DocumentSnapshot forum,
    bool isOwner,
    bool isFollower,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/forumview',
                arguments: forum.id,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildForumIcon(),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildForumContent(forum, isOwner, isFollower),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Color(0xFF81C784)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForumIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.article_outlined, color: Colors.white, size: 28),
    );
  }

  Widget _buildForumContent(
      DocumentSnapshot forum, bool isOwner, bool isFollower) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOwner || isFollower) _buildBadges(isOwner, isFollower),
        if (isOwner || isFollower) SizedBox(height: 4),
        Text(
          forum['title'],
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        _buildTimestamp(forum),
      ],
    );
  }

  Widget _buildBadges(bool isOwner, bool isFollower) {
    return Row(
      children: [
        if (isOwner)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'โพสต์ของฉัน',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (isFollower && !isOwner)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ติดตาม',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimestamp(DocumentSnapshot forum) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          _localeInitialized
              ? DateFormat('d MMM yyyy, HH:mm', 'th')
                  .format((forum['timestamp'] as Timestamp).toDate())
              : DateFormat('d MMM yyyy, HH:mm')
                  .format((forum['timestamp'] as Timestamp).toDate()),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ==================== FLOATING ACTION BUTTON ====================
  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/forumform');
        },
        backgroundColor: Color(0xFF4CAF50),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'สร้างกระทู้',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
