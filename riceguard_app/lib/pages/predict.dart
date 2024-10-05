import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class predictscreen extends StatefulWidget {
  @override
  _predictscreen createState() => _predictscreen();
}

class _predictscreen extends State<predictscreen> {
  File? _image;  
  final ImagePicker _picker = ImagePicker();  

  
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

  
  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      
      String fileName = 'uploads/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
      
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      
      UploadTask uploadTask = storageRef.putFile(_image!);
      await uploadTask.whenComplete(() => null); 

      
      String downloadURL = await storageRef.getDownloadURL();

      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload Successful!'),
      ));
      setState(() {
        _image = null;  
      });
    } catch (e) {
      print('Failed to upload image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to upload image'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Image to Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            
            _image == null
                ? Text('No image selected.')
              
                : Container(
                    width: 400,  
                    height: 400, 
                    child: Image.file(_image!, fit: BoxFit.cover),  
                  ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImageFromGallery, 
                  child: Text('Select from Gallery'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _pickImageFromCamera,  
                  child: Text('Take a Photo'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}