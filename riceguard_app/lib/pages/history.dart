import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'info.dart';

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
                    childAspectRatio: 0.9,
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
    final top3 = data['top3'] as List<dynamic>?;
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
        elevation: 1.5,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailDialog(data, index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section - Left Side
                Hero(
                  tag: 'history_image_$index',
                  child: Container(
                    width: isTablet ? 100 : 85,
                    height: isTablet ? 100 : 85,
                    margin: EdgeInsets.all(isTablet ? 12 : 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit
                                      .contain, // ✅ แก้จาก cover เป็น contain
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
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
                                                AlwaysStoppedAnimation<Color>(
                                                    statusColor),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[400], size: 30),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image,
                                      color: Colors.grey[400], size: 30),
                                ),
                          // Overlay with detail icon
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Section - Right Side
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isTablet ? 12 : 10,
                      right: isTablet ? 12 : 10,
                      bottom: isTablet ? 12 : 10,
                      left: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Disease name - Full width
                        Text(
                          prediction,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 8),

                        // Badge and Confidence in one row
                        Row(
                          children: [
                            if (confidence != null) ...[
                              SizedBox(width: 12),
                              Icon(Icons.analytics_outlined,
                                  size: isTablet ? 14 : 12,
                                  color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                '${(confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: confidence,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        statusColor),
                                    minHeight: isTablet ? 5 : 4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 8),

                        // Timestamp
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: isTablet ? 14 : 12,
                                color: Colors.grey[500]),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 18, color: Colors.grey[400]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> data, int index) {
    final imageUrl = data['imageUrl'] ?? '';
    final prediction = data['prediction'] ?? 'ไม่ทราบผล';
    final confidence = data['confidence'] as double?;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final top3 = data['top3'] as List<dynamic>?;

    final formattedTime = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
        : 'ไม่ทราบเวลา';

    Color statusColor = Colors.green[600]!;
    if (prediction.contains('โรค') || prediction.contains('เสีย')) {
      statusColor = Colors.red[600]!;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Fixed Header (ไม่เลื่อน)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.article, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'รายละเอียดการวิเคราะห์',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // ✅ Scrollable Content (เลื่อนได้)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        if (imageUrl.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () =>
                                _showFullImage(imageUrl, prediction, index),
                            child: Hero(
                              tag: 'history_image_$index',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  statusColor),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(Icons.broken_image,
                                            color: Colors.grey[400], size: 50),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],

                        // Prediction Result
                        _buildInfoSection(
                          icon: Icons.bug_report,
                          title: 'ผลการวิเคราะห์',
                          content: prediction,
                          color: statusColor,
                        ),
                        SizedBox(height: 16),

                        // Confidence Score
                        if (confidence != null) ...[
                          _buildInfoSection(
                            icon: Icons.analytics,
                            title: 'ความมั่นใจ',
                            content:
                                '${(confidence * 100).toStringAsFixed(1)}%',
                            color: statusColor,
                            trailing: LinearProgressIndicator(
                              value: confidence,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 8,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Top 3 Predictions
                        if (top3 != null && top3.isNotEmpty) ...[
                          Text(
                            'โรคที่เป็นไปได้',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 12),
                          ...top3.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final pred = entry.value;
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: idx == 0
                                          ? statusColor
                                          : Colors.grey[400],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pred['class'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          pred['confidence'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 16),
                        ],

                        // Timestamp
                        _buildInfoSection(
                          icon: Icons.schedule,
                          title: 'วันที่วิเคราะห์',
                          content: formattedTime,
                          color: Colors.grey[700]!,
                        ),
                        SizedBox(height: 24),

                        // Action Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => infopage(
                                  diseaseName: prediction,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.info, size: 20),
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'ดูข้อมูลเพิ่มเติม',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
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

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(height: 8),
                trailing,
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showFullImage(String imageUrl, String prediction, int index) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Hero(
                  tag: 'history_image_$index',
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      maxWidth: MediaQuery.of(context).size.width * 0.95,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    color: Colors.white, size: 60),
                                SizedBox(height: 8),
                                Text(
                                  'ไม่สามารถโหลดรูปภาพ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
}
