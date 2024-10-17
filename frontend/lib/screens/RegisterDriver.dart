import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // For handling image bytes

import 'DriverOTP.dart';
import 'login_screen.dart'; // Replace with your login screen

class RegisterDriver extends StatefulWidget {
  @override
  _RegisterDriverState createState() => _RegisterDriverState();
}

class _RegisterDriverState extends State<RegisterDriver> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String firstName = '';
  String lastName = '';
  String password = '';
  String confirmPassword = '';
  String carType = '';
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  Uint8List? drivingLicensePhotoBytes;
  Uint8List? carPlatePhotoBytes;
  Uint8List? idCardPhotoBytes;
  Uint8List? driverPhotoBytes;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto(Function(Uint8List?) onPhotoTaken) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      Uint8List bytes = await image.readAsBytes();
      onPhotoTaken(bytes);
    }
  }

  Widget _buildPhotoButton(String label, Function(Uint8List?) onPhotoTaken) {
    return ElevatedButton(
      onPressed: () => _takePhoto(onPhotoTaken),
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, // Set the background color
        foregroundColor: Colors.white, // Set the text color
      ),
    );
  }

  // Function to handle the registration process and send data to the backend
  Future<void> _registerDriver() async {
    print('First Name: $firstName');
    print('Last Name: $lastName');
    print('Password: $password');
    print('Car Type: $carType');

    final url = Uri.parse('https://your-laravel-backend-url.com/api/register_driver'); // Replace with your Laravel API URL

    try {
      // Prepare the request
      var request = http.MultipartRequest('POST', url);
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['password'] = password;
      request.fields['car_type'] = carType;

      // Add image bytes to the request if available
      if (drivingLicensePhotoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('driving_license_photo', drivingLicensePhotoBytes!, filename: 'driving_license.jpg'));
      }
      if (carPlatePhotoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('car_plate_photo', carPlatePhotoBytes!, filename: 'car_plate.jpg'));
      }
      if (idCardPhotoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('id_card_photo', idCardPhotoBytes!, filename: 'id_card.jpg'));
      }
      if (driverPhotoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('driver_photo', driverPhotoBytes!, filename: 'driver_photo.jpg'));
      }

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseData');

      if (response.statusCode == 200) {
        var responseBody = json.decode(responseData);

        if (responseBody['message'] == 'Registration successful') {
          // Navigate to Login Screen after successful registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DriverOTP()), // Replace with your actual login screen
          );
        } else {
          // Show error message if registration fails
          setState(() {
            _errorMessage = responseBody['message'] ?? 'Registration failed. Please try again.';
          });
        }
      } else {
        // Show error message for non-200 responses
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Register Driver'),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // First Name Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'First Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                onSaved: (value) {
                  firstName = value!;
                },
              ),
              SizedBox(height: 16),

              // Last Name Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
                onSaved: (value) {
                  lastName = value!;
                },
              ),
              SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      isPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  password = value!;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      isConfirmPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Car Type Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Car Type',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your car type';
                  }
                  return null;
                },
                onSaved: (value) {
                  carType = value!;
                },
              ),
              SizedBox(height: 16),

              // Driving License Photo Button
              _buildPhotoButton('Take Driving License Photo', (bytes) {
                setState(() {
                  drivingLicensePhotoBytes = bytes;
                });
              }),
              SizedBox(height: 16),

              // Car Plate Photo Button
              _buildPhotoButton('Take Car Plate Photo', (bytes) {
                setState(() {
                  carPlatePhotoBytes = bytes;
                });
              }),
              SizedBox(height: 16),

              // ID Card Photo Button
              _buildPhotoButton('Take ID Card Photo', (bytes) {
                setState(() {
                  idCardPhotoBytes = bytes;
                });
              }),
              SizedBox(height: 16),

              // User Photo Button
              _buildPhotoButton('Take User Photo', (bytes) {
                setState(() {
                  driverPhotoBytes = bytes;
                });
              }),
              SizedBox(height: 16),

              // Submit Button
              ElevatedButton.icon(
                icon: Icon(FontAwesomeIcons.arrowRight, color: Colors.blue),
                label: Text('Submit', style: TextStyle(color: Colors.blue)),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (drivingLicensePhotoBytes == null || carPlatePhotoBytes == null || idCardPhotoBytes == null || driverPhotoBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Please take all required photos'),
                        backgroundColor: Colors.red,
                      ));
                    } else {
                      _registerDriver(); // Send the form data to backend
                    }
                  }
                },
              ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
