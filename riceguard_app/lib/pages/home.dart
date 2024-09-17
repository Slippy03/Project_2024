import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart'; // Import LoginPage

class HomePage extends StatelessWidget {
  // Function to handle user logout
  Future<void> _logoutUser(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigate back to LoginPage after successful logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Handle logout error if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to log out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Colors.green, // Set the app bar color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to application",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _logoutUser(context); // Call logout function when button is pressed
              },
              child: Text("Logout"),
              style: ElevatedButton.styleFrom(
                primary: Colors.red, // Button color for logout
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
