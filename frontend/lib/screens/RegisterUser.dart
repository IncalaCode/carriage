import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Importing FontAwesome
import 'UserOTP.dart'; // Import the OTP screen
// Importing HTTP package
// For encoding data to JSON

class RegisterUser extends StatefulWidget {
  @override
  _RegisterUserState createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
  final _formKey = GlobalKey<FormState>();
  String firstName = 'cala';
  String lastName = 'cala';
  String password = '12345678';
  String confirmPassword = '12345678';
  bool passwordVisible = false; // To toggle password visibility
  bool confirmPasswordVisible = false; // To toggle confirm password visibility
  String _errorMessage = '';

  // Function to handle registration and navigate to OTP page
  void _registerUser() {
    // Printing entered data to the terminal for debugging
    print('First Name: $firstName');
    print('Last Name: $lastName');
    print('Password: $password');

    // Navigate to OTP page with user data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserOTP(
          firstName: firstName,
          lastName: lastName,
          password: password,
          confirmPassword: confirmPassword, // Correctly reference confirmPassword
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white), // Using FontAwesome for back arrow
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
                  // Logo
                  Image.asset('assets/logo.png', height: 200),
                  SizedBox(height: 20),

                  // First Name Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue), // Blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0), // Thicker blue border on focus
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      firstName = value!; // Save first name
                    },
                  ),
                  SizedBox(height: 16),

                  // Last Name Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue), // Blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0), // Thicker blue border on focus
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      lastName = value!; // Save last name
                    },
                  ),
                  SizedBox(height: 16),

                  // Password Field with Eye Icon
                  TextFormField(
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue), // Blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0), // Thicker blue border on focus
                      ),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          passwordVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                        ), // FontAwesome icon for eye
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      } else if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      password = value; // Update password on change
                    },
                  ),
                  SizedBox(height: 16),

                  // Confirm Password Field with Eye Icon
                  TextFormField(
                    obscureText: !confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue), // Blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0), // Thicker blue border on focus
                      ),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          confirmPasswordVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                        ), // FontAwesome icon for confirm password
                        onPressed: () {
                          setState(() {
                            confirmPasswordVisible = !confirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      confirmPassword = value; // Update confirmPassword on change
                    },
                  ),
                  SizedBox(height: 20),

                  // Error Message Display
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

                  // Next Button with FontAwesome icon
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _registerUser(); // Call the registration function
                      }
                    },
                    icon: FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white), // FontAwesome icon for the button
                    label: Text('Next', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: BorderSide(color: Colors.blue), // Blue border for the button
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
