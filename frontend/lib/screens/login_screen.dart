import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:My_truck/screens/RegisterUser.dart';
import 'package:My_truck/screens/RegisterDriver.dart';
import 'package:My_truck/screens/User/main_app_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'driver/Driver_main_screen.dart ';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// code for the token storing
Future<void> storeToken(String token, String userType) async {
  print('🔑 Storing token: $token with userType: $userType'); // Debug print
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userType', userType); // Store user type
    print('✅ Token and userType stored successfully'); // Debug print
  } catch (e) {
    print('❌ Error storing token and userType: $e'); // Debug print
  }
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
    print('📲 Sending OTP...'); // Debug print
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
      print('📡 OTP Response Status: ${response.statusCode}'); // Debug print
      print('📡 OTP Response Body: ${response.body}'); // Debug print

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
          print('❌ Error: ${response.statusCode}, Message: ${responseBody['message']}');
        });
      }
    } catch (e) {
      print('❌ Exception during OTP send: $e'); // Debug print
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
    print('🔐 Verifying OTP...'); // Debug print
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
      
      print('🔍 Verify Response Status: ${response.statusCode}'); // Debug print

      if (response.statusCode == 200) {
        try {
          var responseBody = json.decode(response.body);
          print('🔍 Verify Response Body: ${responseBody}'); // Debug print

          if (responseBody != null) {
            if (responseBody['message'] == 'OTP verified successfully') {
              if (responseBody.containsKey('user') && responseBody['user'].containsKey('uid')) {
                String token = responseBody['user']['uid'].toString();
                String userType = isUserLogin ? 'user' : 'driver'; // Determine user type
                print('🔑 Received token: $token, userType: $userType'); // Debug print

                if (token.isNotEmpty) {
                  await storeToken(token, userType);

                  // Verify token was stored
                  final prefs = await SharedPreferences.getInstance();
                  final storedToken = prefs.getString('authToken');
                  print('🔍 Verified stored token: $storedToken'); // Debug print

                  if (isUserLogin) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainAppScreen()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DriverMainScreen()),
                    );
                  }
                } else {
                  throw Exception('Empty token received');
                }
              } else {
                throw Exception('No uid field found in user object');
              }
            } else {
              setState(() {
                _errorMessage = responseBody['message'] ?? 'Invalid OTP. Please try again.';
              });
            }
          } else {
            throw Exception('Empty response body');
          }
        } catch (e) {
          print('❌ Error parsing response: $e'); // Debug print
          setState(() {
            _errorMessage = 'Error processing response. Please try again.';
          });
        }
      } else {
        print('❌ Server returned ${response.statusCode}: ${response.body}'); // Debug print
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
      print('❌ Exception during login: $e'); // Debug print
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
                        prefixIcon: Icon(FontAwesomeIcons.phone, color: Colors.grey),
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
                        prefixIcon: Icon(FontAwesomeIcons.lock, color: Colors.grey),
                        hintText: 'Enter OTP',
                        fillColor: Colors.white,
                        filled: true,
                        suffixIcon: ElevatedButton(
                          onPressed: _isOtpSent ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 112, 145, 172),
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            _isOtpSent ? "Resend (${_remainingTime}s)" : "Send OTP",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _otp = value,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
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
                onPressed: _login,
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
