import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:My_truck/screens/main_app_screen.dart';

class UserOTP extends StatefulWidget {
  @override
  _UserOTPState createState() => _UserOTPState();
}

class _UserOTPState extends State<UserOTP> {
  final _formKey = GlobalKey<FormState>();
  String phoneNumber = '';
  String otp = '';
  bool otpVisible = false; // OTP box visibility flag
  Timer? countdownTimer;
  int countdownSeconds = 120; // 2 minutes countdown

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white), // Back icon
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
                      border: OutlineInputBorder( // Add border color
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    validator: (value) {
                      // Ethiopian number validation
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

                  // Send OTP Button with blue border and FontAwesome icon
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        setState(() {
                          otpVisible = true;
                          countdownSeconds = 120;
                        });
                        startCountdown();
                      }
                    },
                    icon: FaIcon(FontAwesomeIcons.solidPaperPlane, color: Colors.blue),
                    label: Text('Send OTP', style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: BorderSide(color: Colors.blue, width: 2), // Add blue border
                    ),
                  ),
                  SizedBox(height: 20),

                  // Countdown Timer Box
                  if (otpVisible)
                    Text(
                      'Time left: ${formatCountdownTime()}',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  SizedBox(height: 20),

                  // OTP Field (only visible after phone number is entered and OTP is sent)
                  if (otpVisible)
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder( // Add border color
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

                  // Confirm Button with blue border and FontAwesome icon
                  if (otpVisible)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          // Assuming OTP is validated here, you can handle the logic
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MainAppScreen()),
                          );
                        }
                      },
                      icon: FaIcon(FontAwesomeIcons.check, color: Colors.blue),
                      label: Text('Confirm', style: TextStyle(color: Colors.blue)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(color: Colors.blue, width: 2), // Add blue border
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
