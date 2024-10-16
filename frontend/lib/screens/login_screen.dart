import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // for jsonEncode
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carriage_app/screens/main_app_screen.dart';

class LoginScreen extends StatelessWidget {
  // Function to send login data to backend and print response to terminal
  Future<void> _sendLoginData(String email, String password) async {
    String apiUrl =
        'https://your-backend-api.com/login'; // Replace with your actual backend URL

    Map<String, String> data = {
      'email': email,
      'password': password,
    };

    print('Sending Login Data: $data');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Login successful. Response from backend: ${response.body}');
      } else {
        print('Login failed. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during login: $error');
    }
  }

  // Function to send registration data to backend and print response to terminal
  Future<void> _sendRegistrationData(String fullName, String phoneNumber,
      String role, String address, String license) async {
    String apiUrl =
        'https://your-backend-api.com/register'; // Replace with your actual backend URL

    Map<String, String> data = {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role, // "user" or "driver"
      'address': address, // Only applicable for driver
      'license': license, // Only applicable for driver
    };

    print('Sending Registration Data: $data');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print(
            'Registration successful. Response from backend: ${response.body}');
      } else {
        print('Registration failed. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during registration: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 200),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                _showLoginPopup(context);
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
                _showRegisterUserPopup(context);
              },
              child: Text("Register as User",
                  style: TextStyle(color: Colors.white)),
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
                _showRegisterDriverPopup(context);
              },
              child: Text("Register as Driver",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginPopup(BuildContext context) {
    String email = '';
    String password = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87.withOpacity(0.85),
          content: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(FontAwesomeIcons.arrowLeft,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Image.asset('assets/logo.png', height: 200),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        email = value;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        password = value;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _sendLoginData(
                            email, password); // Send login data to backend
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MainAppScreen()),
                        );
                      },
                      child:
                          Text('Login', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRegisterUserPopup(BuildContext context) {
    String fullName = '';
    String phoneNumber = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87.withOpacity(10),
          content: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(FontAwesomeIcons.arrowLeft,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Image.asset('assets/logo.png', height: 200),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        fullName = value;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Ethiopian)',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        phoneNumber = value;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _sendRegistrationData(
                            fullName, phoneNumber, 'user', '', '');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MainAppScreen()),
                        );
                      },
                      child: Text('Register',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRegisterDriverPopup(BuildContext context) {
    String fullName = '';
    String address = '';
    String phoneNumber = '';
    String license = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87.withOpacity(0.85),
          content: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(FontAwesomeIcons.arrowLeft,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Image.asset('assets/logo.png', height: 200),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        fullName = value;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Address',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        address = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Upload Driving License',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          license = image.path;
                          print('License Image selected: $license');
                        }
                      },
                      child: Text('Upload Image',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _sendRegistrationData(
                            fullName, phoneNumber, 'driver', address, license);
                        Navigator.pop(context);
                      },
                      child: Text('Register',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
