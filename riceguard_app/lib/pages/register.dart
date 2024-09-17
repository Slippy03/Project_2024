import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'login.dart'; // Import LoginPage

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController(); // Controller for phone number

  bool _obscureTextPassword = true;
  String? _farmerExperience;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _errorMessage;

  // Function to register user with Firebase Auth and Firestore
  Future<void> _registerUser() async {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty) { // Added phone number validation
      try {
        // Create user with email and password using Firebase Authentication
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add additional user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
          'username': _usernameController.text.trim(),
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(), // Store phone number
          'farmer_experience': _farmerExperience,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User registered successfully!"),
          ),
        );

        // Navigate to LoginPage after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
        );
        
      } catch (e) {
        // Handle registration errors
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to register user: $_errorMessage")),
        );
      }
    } else {
      // Show error message if fields are missing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 134, 255, 123), Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Logo and app name
                  Column(
                    children: [
                      Image.asset(
                        'assets/logo.png', // Your app logo path
                        height: 80,
                      ),
                      Text(
                        "RICEGUARD",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "FARMER HELPER APP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Register your account',
                          style: TextStyle(fontSize: 24, color: Colors.orange),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        // Username
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _usernameController.clear();
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureTextPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureTextPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureTextPassword = !_obscureTextPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Name/Surname
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name/Surname',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Phone Number
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Email
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Farmer Experience
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Farmer Experience",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Column(
                          children: <Widget>[
                            RadioListTile<String>(
                              title: const Text('Below 1 year'),
                              value: 'Below 1 year',
                              groupValue: _farmerExperience,
                              onChanged: (String? value) {
                                setState(() {
                                  _farmerExperience = value;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('In 1-3 years'),
                              value: 'In 1-3 years',
                              groupValue: _farmerExperience,
                              onChanged: (String? value) {
                                setState(() {
                                  _farmerExperience = value;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('More than 3 years'),
                              value: 'More than 3 years',
                              groupValue: _farmerExperience,
                              onChanged: (String? value) {
                                setState(() {
                                  _farmerExperience = value;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Register Button
                        ElevatedButton(
                          onPressed: _registerUser,
                          child: Text('Register'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green, // Button color
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          ),
                        ),
                        SizedBox(height: 10),
                        if (_errorMessage != null) // Show error message if any
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
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
