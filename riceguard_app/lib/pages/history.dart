import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'ทั้งหมด';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Responsive utilities
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768;
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
  double _getResponsivePadding(BuildContext context) =>
      _isTablet(context) ? 32 : 20;
  int _getCrossAxisCount(BuildContext context) => _isDesktop(context)
      ? 3
      : _isTablet(context)
          ? 2
          : 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(child: _buildLoginPrompt()),
      );
    }

    final userId = currentUser.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      // เพิ่ม resizeToAvoidBottomInset
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(
              child: _buildHistoryList(userId),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isTablet = _isTablet(context);

    return AppBar(
      backgroundColor: Colors.green[600],
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.history,
                color: Colors.white, size: isTablet ? 28 : 24),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ประวัติการวิเคราะห์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ดูผลการวิเคราะห์โรคข้าวที่ผ่านมา',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isTablet ? 13 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'clear') {
              _showClearHistoryDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep, color: Colors.red[600], size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'ล้างประวัติ',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isTablet = _isTablet(context);
    final padding = _getResponsivePadding(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green[600]!, Colors.green[400]!],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.fromLTRB(padding, 10, padding, 20),
    );
  }

  Widget _buildSearchAndFilter() {
    final padding = _getResponsivePadding(context);
    final isTablet = _isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          Container(
            constraints:
                BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ค้นหาผลการวิเคราะห์...',
                hintStyle: TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.green[600]),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['ทั้งหมด', 'วันนี้', 'สัปดาห์นี้', 'เดือนนี้'].map((filter) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) =>
                        setState(() => _selectedFilter = filter),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.green[100],
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter
                          ? Colors.green[800]
                          : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('predict_History')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final allDocs = snapshot.data!.docs;
        final filteredDocs = _filterDocuments(allDocs, userId);

        if (filteredDocs.isEmpty) {
          return _buildEmptyState();
        }

        final crossAxisCount = _getCrossAxisCount(context);
        final padding = _getResponsivePadding(context);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: crossAxisCount == 1
              ? ListView.builder(
                  padding: EdgeInsets.all(padding),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildHistoryCard(data, index);
                  },
                )
              : GridView.builder(
                  padding: EdgeInsets.all(padding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildHistoryCard(data, index);
                  },
                ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterDocuments(
      List<QueryDocumentSnapshot> docs, String userId) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Filter by user
      if (data['userId'] != userId) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final prediction = (data['prediction'] ?? '').toString().toLowerCase();
        if (!prediction.contains(_searchQuery.toLowerCase())) return false;
      }

      // Filter by time period
      if (_selectedFilter != 'ทั้งหมด') {
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final now = DateTime.now();
          switch (_selectedFilter) {
            case 'วันนี้':
              if (!_isSameDay(timestamp, now)) return false;
              break;
            case 'สัปดาห์นี้':
              if (now.difference(timestamp).inDays > 7) return false;
              break;
            case 'เดือนนี้':
              if (now.difference(timestamp).inDays > 30) return false;
              break;
          }
        }
      }

      return true;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, int index) {
    final imageUrl = data['imageUrl'] ?? '';
    final prediction = data['prediction'] ?? 'ไม่ทราบผล';
    final confidence = data['confidence'] as double?;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final deviceInfo = data['deviceInfo'] ?? 'ไม่ทราบอุปกรณ์';
    final isTablet = _isTablet(context);
    final isDesktop = _isDesktop(context);

    final formattedTime = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
        : 'ไม่ทราบเวลา';

    // Determine status color based on prediction
    Color statusColor = Colors.green[600]!;
    IconData statusIcon = Icons.check_circle;
    if (prediction.contains('โรค') || prediction.contains('เสีย')) {
      statusColor = Colors.red[600]!;
      statusIcon = Icons.warning;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - แก้ไขตรงนี้
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon,
                          color: statusColor, size: isTablet ? 22 : 18),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prediction,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  child: isDesktop
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Image
                            Flexible(
                              child: _buildImage(imageUrl, statusColor, index),
                            ),
                            SizedBox(height: 12),
                            // Details
                            _buildDetailsSection(
                                confidence, statusColor, deviceInfo),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              _buildImage(imageUrl, statusColor, index,
                                  size: isTablet ? 80 : 65),
                              SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: _buildDetailsSection(
                                    confidence, statusColor, deviceInfo),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl, Color statusColor, int index,
      {double? size}) {
    return Hero(
      tag: 'image_$index',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image,
                          color: Colors.grey[400], size: 24),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey[400], size: 24),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(
      double? confidence, Color statusColor, String deviceInfo) {
    final isTablet = _isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (confidence != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics,
                  size: isTablet ? 16 : 14, color: Colors.blue[600]),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'ความแม่นยำ',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: isTablet ? 7 : 5,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smartphone,
                size: isTablet ? 14 : 12, color: Colors.grey[500]),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                deviceInfo,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isTablet = _isTablet(context);
    final padding = _getResponsivePadding(context);

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(isTablet ? 40 : 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[100]!, Colors.green[50]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.history,
                    size: isTablet ? 80 : 60,
                    color: Colors.green[600],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'ยังไม่มีประวัติการวิเคราะห์',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'เริ่มต้นด้วยการถ่ายรูปใบข้าว\nเพื่อวิเคราะห์โรคและสร้างประวัติ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[500]!],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/camera'),
                    icon: Icon(Icons.camera_alt, size: isTablet ? 24 : 20),
                    label: Text(
                      'เริ่มวิเคราะห์',
                      style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 30,
                          vertical: isTablet ? 16 : 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
          SizedBox(height: 16),
          Text(
            'กำลังโหลดประวัติ...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh, size: 18),
              label: Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.login,
              size: 60,
              color: Colors.green[600],
            ),
            SizedBox(height: 16),
            Text(
              'กรุณาเข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'เพื่อดูประวัติการวิเคราะห์โรคข้าว',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: Icon(Icons.login, size: 20),
              label: Text('เข้าสู่ระบบ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์สถิติจะเปิดใช้งานเร็วๆ นี้'),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.red[600], size: 24),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'ล้างประวัติ',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการลบประวัติการวิเคราะห์ทั้งหมดหรือไม่?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => _clearHistory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    Navigator.pop(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('predict_History')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'ลบประวัติเรียบร้อยแล้ว',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'เกิดข้อผิดพลาด: ${e.toString()}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.blue[600], size: 24),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'ส่งออกข้อมูล',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการส่งออกประวัติการวิเคราะห์หรือไม่?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ฟีเจอร์ส่งออกข้อมูลจะเปิดใช้งานเร็วๆ นี้'),
                  backgroundColor: Colors.blue[600],
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text('ส่งออก'),
          ),
        ],
      ),
    );
  }
}
