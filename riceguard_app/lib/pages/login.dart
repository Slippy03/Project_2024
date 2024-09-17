import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart'; // Import the HomePage
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  // Function to determine if a string is an email
  bool _isEmail(String input) {
    return RegExp(r"^[\w-]+@([\w-]+\.)+[a-zA-Z]{2,}$").hasMatch(input);
  }

  // Function to log in user
  Future<void> _loginUser() async {
    String input = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (input.isNotEmpty && password.isNotEmpty) {
      try {
        String email;

        if (_isEmail(input)) {
          // If input is an email, use it directly
          email = input;
        } else {
          // If input is a username, fetch email associated with it
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            email = querySnapshot.docs[0]['email'];
          } else {
            // Username not found
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Username not found")),
            );
            return;
          }
        }

        // Sign in with the obtained email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        // If login is successful, navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        // Handle errors (e.g., wrong password, network issue)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both username and password")),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo and app name
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Your app logo path
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
                        'Welcome',
                        style: TextStyle(fontSize: 24, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username/Email',
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
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loginUser, // Call login function
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green, // Button color
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterPage()),
                          );
                        },
                        child: Text(
                          "If you do not have an account, please Register.",
                          style: TextStyle(color: Colors.blue),
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
    );
  }
}
