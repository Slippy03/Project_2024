import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PredictScreeen extends StatefulWidget {
  @override
  _PredictScreeenState createState() => _PredictScreeenState();
}

class _PredictScreeenState extends State<PredictScreeen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _predictionResult; // ✅ เปลี่ยนเป็น Map
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _predictionResult = null;
      });
    }
  }

  Future<void> _uploadAndPredictImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_image == null || user == null) return;

    setState(() => _isLoading = true);

    try {
      // Resize image
      File resizedImage = await _resizeImage(_image!);

      // Upload to Firebase Storage
      String fileName =
          'uploads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = storageRef.putFile(resizedImage);
      await uploadTask.whenComplete(() => null);

      String downloadURL = await storageRef.getDownloadURL();

      // Predict via API
      final result = await _predictImage(downloadURL);

      if (result == null || result['status'] == 'error') {
        throw Exception(result?['message'] ?? 'Prediction failed');
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('predict_History').add({
        'imageUrl': downloadURL,
        'prediction': result['predicted_class'],
        'confidence': result['confidence_value'] / 100, // แปลงเป็น 0-1
        'top3': result['top_3_predictions'],
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('✅ อัปโหลดและวิเคราะห์สำเร็จ!'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Clear image after success
      setState(() {
        _image = null;
      });
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('❌ เกิดข้อผิดพลาด: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File> _resizeImage(File image) async {
    img.Image? imageFile = img.decodeImage(await image.readAsBytes());
    if (imageFile == null) throw Exception("Error decoding image");

    img.Image resized = img.copyResize(imageFile, width: 256, height: 256);

    final resizedFile = File('${image.path}_resized.jpg')
      ..writeAsBytesSync(img.encodeJpg(resized));
    return resizedFile;
  }

  Future<Map<String, dynamic>?> _predictImage(String imageUrl) async {
    try {
      // เรียก API
      final result = await ApiService.predictImage(imageUrl);

      if (result == null) {
        throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
      }

      setState(() {
        _predictionResult = result;
      });

      // แสดง Dialog
      _showPredictionDialog(result, imageUrl);

      return result;
    } catch (e) {
      print('Prediction error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ การวิเคราะห์ล้มเหลว: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  void _showPredictionDialog(Map<String, dynamic> result, String imageUrl) {
    // จัดรูปแบบข้อความ
    final String formattedResult = ApiService.formatPredictionResult(result);
    final bool isSuccess = result['status'] == 'success';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? Colors.green[100]
                                : Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSuccess ? Icons.check_circle : Icons.warning,
                            color: isSuccess
                                ? Colors.green[700]
                                : Colors.orange[700],
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ผลการวิเคราะห์',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                result['confidence_score'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(),
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
                    SizedBox(height: 20),

                    // Prediction Result
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        formattedResult,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.close, size: 20),
                            label: Text("ปิด"),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (isSuccess) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushNamed(
                                  context,
                                  '/googlemap',
                                  arguments: {
                                    'description': result['predicted_class'],
                                    'imageUrl': imageUrl,
                                    'confidence': result['confidence_score'],
                                    'fullResult': result,
                                  },
                                );
                              },
                              icon: Icon(Icons.map, size: 20),
                              label: Text("เพิ่มใน Map"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'ยังไม่ได้เลือกรูปภาพ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'กรุณาเลือกรูปภาพจากแกลเลอรี่หรือถ่ายรูปใหม่',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.file(
                _image!,
                height: 280,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() {
                        _image = null;
                        _predictionResult = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, size: 24),
            SizedBox(width: 8),
            Text('วิเคราะห์โรคข้าว'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Preview
                  _buildImagePreview(),
                  SizedBox(height: 32),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'เลือกรูปภาพใบข้าวที่มีอาการเพื่อวิเคราะห์โรค',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Pick Image Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: Icon(Icons.photo_library, size: 22),
                          label: Text("แกลเลอรี่"),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.green[600]!, width: 1.5),
                            foregroundColor: Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          icon: Icon(Icons.camera_alt, size: 22),
                          label: Text("กล้อง"),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.orange[600]!, width: 1.5),
                            foregroundColor: Colors.orange[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Upload & Predict Button
                  ElevatedButton.icon(
                    onPressed: (_isLoading || _image == null)
                        ? null
                        : _uploadAndPredictImage,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.cloud_upload, size: 22),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _isLoading
                            ? 'กำลังวิเคราะห์...'
                            : 'อัปโหลดและวิเคราะห์',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
