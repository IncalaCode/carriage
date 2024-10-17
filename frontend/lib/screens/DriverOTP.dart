import 'dart:async';
import 'dart:convert'; // For encoding/decoding JSON
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:My_truck/screens/main_app_screen.dart';

class DriverOTP extends StatefulWidget {
  @override
  _DriverOTPState createState() => _DriverOTPState();
}

class _DriverOTPState extends State<DriverOTP> {
  final _formKey = GlobalKey<FormState>();
  String phoneNumber = '';
  String otp = '';
  bool otpVisible = false;
  Timer? countdownTimer;
  int countdownSeconds = 120; // 2 minutes countdown
  String generatedOtp = ''; // Store OTP for debugging

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdownSeconds > 0) {
        setState(() {
          countdownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String formatCountdownTime() {
    int minutes = countdownSeconds ~/ 60;
    int seconds = countdownSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Function to send phone number and request OTP
  Future<void> sendPhoneNumber() async {
    final url = Uri.parse('https://your-backend-api/send-otp'); // Replace with your backend URL

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          otpVisible = true;
          countdownSeconds = 120;
          generatedOtp = data['otp']; // Assuming the OTP is returned here
        });
        startCountdown();
        print('OTP sent to user: $generatedOtp'); // Print OTP for debugging
      } else {
        print('Failed to send OTP');
      }
    } catch (e) {
      print('Error sending OTP: $e');
    }
  }

  // Function to verify OTP
  Future<void> verifyOtp() async {
    final url = Uri.parse('https://your-backend-api/verify-otp'); // Replace with your backend URL

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'otp': otp
        }),
      );

      if (response.statusCode == 200) {
        // If OTP is verified, navigate to the login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainAppScreen()),
        );
      } else {
        print('OTP verification failed');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', height: 200), // Logo
                  SizedBox(height: 20),

                  // Phone Number Field
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (Ethiopian)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || !RegExp(r'^(\+251|0)[1-9]\d{8}$').hasMatch(value)) {
                        return 'Enter a valid Ethiopian phone number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      phoneNumber = value!;
                    },
                  ),
                  SizedBox(height: 20),

                  // Send OTP Button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        sendPhoneNumber(); // Send phone number to backend
                      }
                    },
                    icon: FaIcon(FontAwesomeIcons.solidPaperPlane, color: Colors.blue),
                    label: Text('Send OTP', style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Countdown Timer
                  if (otpVisible)
                    Text(
                      'Time left: ${formatCountdownTime()}',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  SizedBox(height: 20),

                  // OTP Field
                  if (otpVisible)
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        otp = value!;
                      },
                    ),
                  SizedBox(height: 20),

                  // Confirm Button
                  if (otpVisible)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          verifyOtp(); // Verify OTP with backend
                        }
                      },
                      icon: FaIcon(FontAwesomeIcons.check, color: Colors.blue),
                      label: Text('Confirm', style: TextStyle(color: Colors.blue)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(color: Colors.blue, width: 2),
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
