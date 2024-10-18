import 'package:flutter/material.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:My_truck/screens/RegisterUser.dart';
import 'package:My_truck/screens/RegisterDriver.dart';
import 'package:My_truck/screens/main_app_screen.dart';
import 'package:My_truck/screens/Driver_main_screen.dart'; // Your Driver's main screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Track if the current mode is user or driver login
  bool isUserLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main logo at the top
              Image.asset('assets/logo.png', height: 250), // Smaller logo as per request
              SizedBox(height: 50),

              // Switch between User and Driver Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // User Login option
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
                  
                  // Driver Login option
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

              // Username and password fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("user name", style: TextStyle(color: Colors.white, fontSize: 20)),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.person),
                        hintText: 'User Name',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("password", style: TextStyle(color: Colors.white, fontSize: 20)),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.lock),
                        hintText: 'Password',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Login button with blue border
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue, width: 2), // Blue border
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  if (isUserLogin) {
                    // Redirect to main app screen for users
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainAppScreen()),
                    );
                  } else {
                    // Redirect to the driver-specific screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DriverAppScreen()), // Replace with the actual Driver screen
                    );
                  }
                },
                child: Text("Login", style: TextStyle(color: Colors.white)),
              ),

              SizedBox(height: 20),

              // Register Button (changes based on login type)
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
                    // Navigate to RegisterUser page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterUser()),
                    );
                  } else {
                    // Navigate to RegisterDriver page
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
