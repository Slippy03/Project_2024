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
  String? _predictionResult;
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
      File resizedImage = await _resizeImage(_image!);

      String fileName =
          'uploads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = storageRef.putFile(resizedImage);
      await uploadTask.whenComplete(() => null);

      String downloadURL = await storageRef.getDownloadURL();

      await _predictImage(downloadURL);

      await FirebaseFirestore.instance.collection('predict_History').add({
        'imageUrl': downloadURL,
        'prediction': _predictionResult,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Upload and Predict Successful!')),
      );

      setState(() {
        _image = null;
      });
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Upload Failed')),
      );
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

  Future<void> _predictImage(String imageUrl) async {
    try {
      final result = await ApiService.predictImage(imageUrl);

      setState(() {
        _predictionResult = result;
      });

      _showPredictionDialog(_predictionResult!, imageUrl);
    } catch (e) {
      print('Prediction error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Prediction Failed')),
      );
    }
  }

  void _showPredictionDialog(String predictionResult, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🧠 Prediction Result',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  predictionResult,
                  style: TextStyle(fontSize: 16, color: Colors.teal[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("OK"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        Navigator.pushNamed(
                          context,
                          '/googlemap',
                          arguments: {
                            'description': predictionResult,
                            'imageUrl': imageUrl,
                          },
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text("Add to Map"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('🖼️ No image selected',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    } else {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_image!,
              height: 260, width: double.infinity, fit: BoxFit.cover),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌾 Upload & Predict'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildImagePreview(),
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade100,
                      foregroundColor: Colors.teal.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadAndPredictImage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text("Upload & Predict"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}
