import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:My_truck/screens/RegisterUser.dart';
import 'package:My_truck/screens/RegisterDriver.dart';
import 'package:My_truck/screens/main_app_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isUserLogin = true;
  String _email = '';
  String _password = '';
  String _errorMessage = '';

  // Function to handle login and send data to the backend
  Future<void> _login() async {
    print('Email: $_email');
    print('Password: $_password');

    final url = Uri.parse('https://your-laravel-backend-url.com/api/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'email': _email,
          'password': _password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Assuming the backend returns a success message in the body
        var responseBody = json.decode(response.body);

        if (responseBody['message'] == 'Login successful') {
          // Navigate to the main app screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainAppScreen()),
          );
        } else {
          // Show an error prompt if the login failed
          setState(() {
            _errorMessage = 'Login failed. Please check your credentials and try again.';
          });
        }
      } else {
        // Show an error prompt if the response status is not 200
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials and try again.';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 250),
              SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        isUserLogin = true;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'User Login',
                          style: TextStyle(
                            color: isUserLogin ? Colors.white : Colors.grey,
                            fontSize: 20,
                            fontWeight: isUserLogin ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 5),
                        isUserLogin ? Container(height: 2, width: 60, color: Colors.blue) : Container(),
                      ],
                    ),
                  ),
                  SizedBox(width: 30),
                  InkWell(
                    onTap: () {
                      setState(() {
                        isUserLogin = false;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Driver Login',
                          style: TextStyle(
                            color: !isUserLogin ? Colors.white : Colors.grey,
                            fontSize: 20,
                            fontWeight: !isUserLogin ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 5),
                        !isUserLogin ? Container(height: 2, width: 60, color: Colors.blue) : Container(),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("User Name", style: TextStyle(color: Colors.white, fontSize: 20)),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.person),
                        hintText: 'User Name',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (value) {
                        _email = value;
                      },
                    ),
                    SizedBox(height: 20),
                    Text("Password", style: TextStyle(color: Colors.white, fontSize: 20)),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.lock),
                        hintText: 'Password',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (value) {
                        _password = value;
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Show error message if login fails
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _login, // Call the login function
                child: Text("Login", style: TextStyle(color: Colors.white)),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  if (isUserLogin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterUser()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterDriver()),
                    );
                  }
                },
                child: Text(
                  isUserLogin ? "Register as User" : "Register as Driver",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
