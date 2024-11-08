import 'dart:async';
import 'dart:convert'; // For encoding/decoding JSON
import 'dart:typed_data'; // For handling image bytes
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:http_parser/http_parser.dart'; // For setting content type of image
import 'config.dart'; // Ensure this points to your correct config file
import 'login_screen.dart';

class DriverOTP extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String password;
  final String confirm_password;
  final String carType;
  final Uint8List? drivingLicensePhoto;
  final Uint8List? carPlatePhoto;
  final Uint8List? idCardPhoto;
  final Uint8List? driverPhoto;
  // final String driverId; // Ensure this field exists

  DriverOTP({
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.confirm_password,
    required this.carType,
    // required this.driverId, // Driver ID is now required
    this.drivingLicensePhoto,
    this.carPlatePhoto,
    this.idCardPhoto,
    this.driverPhoto,
  });

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

  // Function to send phone number and all collected data to backend and request OTP
  Future<void> sendDriverDataAndRequestOtp() async {
    final url = Uri.parse(Config.baseUrl + '/driver/register'); // Your Laravel API

    try {
      var request = http.MultipartRequest('POST', url);

      // Add text fields, ensuring field names match Laravel's expectations
      request.fields['first_name'] = widget.firstName;
      request.fields['last_name'] = widget.lastName;
      request.fields['password'] = widget.password;
      request.fields['password_confirmation'] = widget.confirm_password;
      request.fields['car_type'] = widget.carType;
      request.fields['phone_number'] = phoneNumber;
      // request.fields['driver_id'] = widget.driverId; // Driver ID is added

      // Add image files if available and not null
      if (widget.drivingLicensePhoto != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'driver_license_photo', // Use 'driver_license_photo' as expected in backend
            widget.drivingLicensePhoto!,
            filename: 'driving_license.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      if (widget.carPlatePhoto != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'car_plate_photo', // Corrected field name for car plate photo
            widget.carPlatePhoto!,
            filename: 'car_plate.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      if (widget.idCardPhoto != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'id_card_image', // Corrected field name for id card photo
            widget.idCardPhoto!,
            filename: 'id_card.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      if (widget.driverPhoto != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'user_photo', // Corrected field name for driver photo
            widget.driverPhoto!,
            filename: 'driver_photo.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Send request and handle the response
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        setState(() {
          otpVisible = true;
          countdownSeconds = 120;
        });
        startCountdown();
      } else {
        print('Failed to send data and request OTP. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending data and requesting OTP: $e');
    }
  }

  // Function to verify OTP
  Future<void> verifyOtp() async {
    final url = Uri.parse(Config.baseUrl + "/driver/verify");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        print('OTP verification failed. Status Code: ${response.statusCode}');
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
                        // Ensure password meets minimum length requirement
                        if (widget.password.length < 8) {
                          print("Password must be at least 8 characters.");
                          return;
                        }
                        sendDriverDataAndRequestOtp(); // Send data and request OTP
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
