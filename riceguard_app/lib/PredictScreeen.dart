import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictScreeen extends StatefulWidget {
  @override
  _PredictScreeenState createState() => _PredictScreeenState();
}

class _PredictScreeenState extends State<PredictScreeen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _predictionResult;

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadAndPredictImage() async {
    if (_image == null) return;

    try {
      String fileName =
          'uploads/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = storageRef.putFile(_image!);
      await uploadTask.whenComplete(() => null);

      String downloadURL = await storageRef.getDownloadURL();

      await _predictImage(downloadURL);

      await FirebaseFirestore.instance.collection('predict_History').add({
        'imageUrl': downloadURL,
        'prediction': _predictionResult,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload and Predict Successful!')),
      );

      setState(() {
        _image = null;
      });
    } catch (e) {
      print('Failed to upload image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  Future<void> _predictImage(String imageUrl) async {
    try {
      final result = await ApiService.predictImage(imageUrl);

      setState(() {
        _predictionResult = result;
      });

      _showPredictionDialog(_predictionResult!, imageUrl);
    } catch (e) {
      print('Failed to predict image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to predict image')),
      );
    }
  }

  void _showPredictionDialog(String predictionResult, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Prediction Result',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    
                    Image.network(imageUrl,
                        height: 200, width: 200, fit: BoxFit.cover),
                    const SizedBox(height: 10),

                    
                    Text(predictionResult,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              
              Positioned(
                right: 0.0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image and Predict'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? const Text('No image selected.')
                : Container(
                    width: 400,
                    height: 400,
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: const Text('Select from Gallery'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _pickImageFromCamera,
                  child: const Text('Take a Photo'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadAndPredictImage,
              child: const Text('Upload and Predict'),
            ),
          ],
        ),
      ),
    );
  }
}
