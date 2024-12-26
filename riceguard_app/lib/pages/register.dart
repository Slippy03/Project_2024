import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'login.dart'; 

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController(); 

  bool _obscureTextPassword = true;
  String? _farmerExperience;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _errorMessage;

  Future<void> _registerUser() async {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty) { 
     
      bool? confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Registration'),
            content: Text('กรุณาตรวจสอบข้อมูลอย่างถี่ถ้วน หากเรียบร้อยแล้วโปรดกดยืนยัน'),
            actions: <Widget>[
              TextButton(
                child: Text('ยกเลิก'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('ยืนยัน'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        return; 
      }

      try {
        QuerySnapshot usernameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: _usernameController.text.trim())
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("มีชื่อผู้ใช้นี้ในระบบแล้ว"),backgroundColor: Colors.red,),
          );
          return;
        }

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
          'username': _usernameController.text.trim(),
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null, 
          'farmer_experience': _farmerExperience,
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ละทะเบียนสำเร็จ!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()), 
        );
        
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ลงทะเบียนไม่สำเร็จ: $_errorMessage"),backgroundColor: Colors.red,),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน!"),
        backgroundColor: Colors.red,),
        
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 134, 255, 123),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 255, 255)), 
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()), 
            );
          },
        ),
      ),
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
                  
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/farmer.png', 
                        height: 100,
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
                        Align(
                          alignment: Alignment.centerLeft,
                            child: Text(
                              'Register your account',
                              style: TextStyle(fontSize: 24, color: Colors.orange),
                              textAlign: TextAlign.center,
                            ),
                        ),
                        SizedBox(height: 20),
                        
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
                        
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name/Surname',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20),
                        
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
                        ElevatedButton(
                          onPressed: _registerUser,
                          child: Text('Register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, 
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            foregroundColor: Colors.white                         

                          ),
                        ),
                        SizedBox(height: 10),
                        if (_errorMessage != null) 
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
