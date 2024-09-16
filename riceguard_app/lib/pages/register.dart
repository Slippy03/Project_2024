import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  bool _obscureTextPassword = true;
  String? _farmerExperience; // For radio button selection

  // Function to add user data to Firestore
  Future<void> _registerUser() async {
    // Validate if the required fields are not empty
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _nameController.text.isNotEmpty) {
      try {
        // Add user data to Firestore
        await FirebaseFirestore.instance.collection('users').add({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'name': _nameController.text,
          'email': _emailController.text.isEmpty ? null : _emailController.text, // Optional field
          'farmer_experience': _farmerExperience,
          'created_at': FieldValue.serverTimestamp(), // To store the timestamp
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User registered successfully!"),),
        );
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to register user: $e")),
        );
      }
    } else {
      // Show an error message if fields are empty
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
            colors: [Colors.greenAccent, Colors.white],
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
                        // Email (Optional)
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email (Optional)',
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
