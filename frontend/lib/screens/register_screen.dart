import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // This method sends data to the backend and logs everything in the terminal
  Future<void> _sendRegistrationData(String fullName, String phoneNumber) async {
    Map<String, String> data = {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };

    // Log the collected data in the terminal
    print("Sending the following data to backend:");
    print("Full Name: $fullName, Phone Number: $phoneNumber");

    try {
      final response = await http.post(
        Uri.parse(Config.baseUrl + '/user/register'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      // Log the backend response in the terminal
      if (response.statusCode == 200) {
        print('Registration successful. Response from backend: ${response.body}');
      } else {
        print('Registration failed. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending registration data: $error');
    }
  }

  // This method is called when the user submits the form
  void _register() {
    if (_formKey.currentState!.validate()) {
      // Collect form data
      String fullName = _fullNameController.text;
      String phoneNumber = _phoneNumberController.text;

      // Send data to backend and display in terminal
      _sendRegistrationData(fullName, phoneNumber);

      // Navigate back or show success message (optional)
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
