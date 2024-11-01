import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:My_truck/screens/RegisterUser.dart';
import 'package:My_truck/screens/RegisterDriver.dart';
import 'package:My_truck/screens/main_app_screen.dart';
import 'package:My_truck/screens/Driver_main_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isUserLogin = true;
  String _phoneNumber = '';
  String _otp = '';
  String _errorMessage = '';
  bool _isOtpSent = false;
  bool _isOtpValid = false;
  int _remainingTime = 60;
  Timer? _timer;

  // Function to handle sending OTP
  Future<void> _sendOtp() async {
    // Check phone number format
    if (!_phoneNumber.startsWith('+251') || _phoneNumber.length != 13) {
      setState(() {
        _errorMessage = 'Phone number must be in +251 xxxxxxxxx format';
      });
      return;
    }

    // API URL for sending OTP
    final url = Uri.parse(Config.baseUrl + '/${isUserLogin ? 'user' : 'driver'}/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'phone_number': _phoneNumber
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isOtpSent = true;
          _errorMessage = '';
        });
        _startOtpTimer();
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP. Try again later.';
          final responseBody = json.decode(response.body);
          print('Error: ${response.statusCode}, Message: ${responseBody['message']}');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  // Function to handle OTP timer
  void _startOtpTimer() {
    _remainingTime = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isOtpSent = false; // Allow resend after 60 seconds
        });
      }
    });
  }

  // Function to handle login
  Future<void> _login() async {
    // this is the back door so when it is finished remove this 
              Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DriverMainScreen()),
          );

    // ------------------------------------------------------------------



    if (_otp.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a valid 4-digit OTP';
      });
      return;
    }

    final url = Uri.parse(Config.baseUrl + '/${isUserLogin ? 'user' : 'driver'}/verify');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'phone_number': _phoneNumber,
          'otp': _otp
        }),
      );

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        if (responseBody['message'] == 'OTP verified successfully') {
          // Navigate to the main app screen after successful verification
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainAppScreen()),
          );
        } else {
          setState(() {
            _errorMessage = 'Invalid OTP. Please try again.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                    onTap: () => setState(() => isUserLogin = true),
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
                    onTap: () => setState(() => isUserLogin = false),
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
                    Text("Phone Number", style: TextStyle(color: Colors.white, fontSize: 20)),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.phone),
                        hintText: '+251 xxxxxxxxx',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _phoneNumber = value,
                    ),
                    SizedBox(height: 20),
                    Text("OTP", style: TextStyle(color: Colors.white, fontSize: 20)),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.lock),
                        hintText: 'Enter OTP',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _otp = value,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isOtpSent ? null : _sendOtp,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(_isOtpSent ? "Resend OTP in $_remainingTime s" : "Send OTP"),
              ),
              SizedBox(height: 20),
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
                      MaterialPageRoute(builder: (context) => DriverMainScreen()), // Replace with the actual Driver screen
                    );
                  }
                },
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