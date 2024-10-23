import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:My_truck/screens/main_app_screen.dart';
import 'config.dart';

class UserOTP extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String password;
  final String confirmPassword;

  UserOTP({
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.confirmPassword,
  });

  @override
  _UserOTPState createState() => _UserOTPState();
}

class _UserOTPState extends State<UserOTP> {
  final _formKey = GlobalKey<FormState>();
  String phoneNumber = '';
  String otp = '';
  bool otpVisible = false;
  bool isLoading = false;
  bool otpSent = false; // Flag to show success message
  bool allowResendOtp = false; // Flag to allow resending OTP
  Timer? countdownTimer;
  int countdownSeconds = 120;
  String receivedOtp = '';
  String _errorMessage = '';

  @override
  void dispose() {
    countdownTimer?.cancel(); // Ensure timer is cancelled on dispose
    super.dispose();
  }

  // Start Countdown for OTP Resend
  void startCountdown() {
    countdownTimer?.cancel(); // Cancel any existing timer
    countdownSeconds = 120; // Reset the countdown time
    setState(() {
      allowResendOtp = false; // Disable resend button initially
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds > 0) {
        setState(() {
          countdownSeconds--; // Decrement the countdown every second
        });
        print('Countdown: $countdownSeconds'); // Debugging: Print countdown to console
      } else {
        timer.cancel(); // Stop the timer when time is up
        setState(() {
          allowResendOtp = true; // Enable resend button when time is up
        });
      }
    });
  }

  // Format Countdown Timer
  String formatCountdownTime() {
    final minutes = countdownSeconds ~/ 60;
    final seconds = countdownSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Send Phone Number and OTP Request
  Future<void> sendPhoneNumber() async {
    final url = Uri.parse(Config.baseUrl + '/user/register');

    setState(() {
      isLoading = true;
      _errorMessage = '';
      otpSent = false;
      otpVisible = false;
      allowResendOtp = false; // Reset the resend flag
    });

    try {
      String formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': widget.firstName,
          'last_name': widget.lastName,
          'password': widget.password,
          'password_confirmation': widget.confirmPassword,
          'phone_number': formattedPhoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          otpVisible = true;
          otpSent = true; // Show success message
          receivedOtp = data['otp']; // Assuming the OTP is returned here
        });
        startCountdown(); // Start the countdown when OTP is sent
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending OTP: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Verify OTP
  Future<void> verifyOtp() async {
    final url = Uri.parse(Config.baseUrl + '/api/verifyOtp');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainAppScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'OTP verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying OTP: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
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
                  Image.asset('assets/logo.png', height: 200),
                  const SizedBox(height: 20),

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
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      String formattedPhoneNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (formattedPhoneNumber.length < 1 || formattedPhoneNumber.length > 15) {
                        return 'Phone number must be between 1 and 15 digits';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      phoneNumber = value!.replaceAll(RegExp(r'[^0-9]'), '').trim();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Loading Indicator or Success Message
                  if (isLoading) const CircularProgressIndicator(),
                  if (!isLoading && otpSent) const Text('OTP sent successfully!', style: TextStyle(color: Colors.green)),

                  // Send OTP Button or Resend OTP Button
                  if (!isLoading && !otpVisible)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          sendPhoneNumber();
                        }
                      },
                      icon: const FaIcon(FontAwesomeIcons.solidPaperPlane, color: Colors.blue),
                      label: Text('Send OTP', style: const TextStyle(color: Colors.blue)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),

                  // Countdown Timer or Resend Button
                  if (otpVisible)
                    Column(
                      children: [
                        Text(
                          'Time left: ${formatCountdownTime()}',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        if (countdownSeconds == 0 && allowResendOtp)
                          ElevatedButton(
                            onPressed: () {
                              sendPhoneNumber();
                            },
                            child: const Text('Resend OTP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                      ],
                    ),

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
                  const SizedBox(height: 20),

                  // Confirm Button
                  if (otpVisible)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          verifyOtp();
                        }
                      },
                      icon: const FaIcon(FontAwesomeIcons.check, color: Colors.blue),
                      label: Text('Confirm', style: const TextStyle(color: Colors.blue)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),

                  // Error Message Display
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
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
