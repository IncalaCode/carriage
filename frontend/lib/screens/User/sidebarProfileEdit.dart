import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final File? profileImage;
  final String firstName;
  final String lastName;
  final String phoneNumber;

  EditProfilePage({
    Key? key,
    required this.profileImage,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool isNewPhoneNumber = false;
  bool showOTPField = false;

  // TextEditingControllers for the form fields
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.firstName;
    _lastNameController.text = widget.lastName;
    _phoneController.text = widget.phoneNumber;
    _profileImage = widget.profileImage;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _onPhoneNumberChanged(String newPhoneNumber) {
    setState(() {
      isNewPhoneNumber = newPhoneNumber != widget.phoneNumber;
      showOTPField = isNewPhoneNumber;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // New method to send OTP
  Future<void> _sendOTP() async {
    final String newPhoneNumber = _phoneController.text;

    if (newPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      "phone_number": newPhoneNumber,
    };

    // Print the request body for debugging
    print('Sending OTP Request Body: $requestBody');

    // Send the request to the backend
    final response = await http.post(
      Uri.parse(Config.baseUrl + '/profile/send-otp'), // Replace with your actual backend URL for sending OTP
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // Print the response status code for debugging
    print('Send OTP Response Status Code: ${response.statusCode}');

    // Handle the response
    if (response.statusCode == 200) {
      // Assuming the response contains the OTP or a success message
      final responseBody = jsonDecode(response.body);
      print('Send OTP Response Body: $responseBody'); // Print the response body for debugging

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP Sent!')),
      );
      print('OTP sent successfully.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP. Status: ${response.statusCode}')),
      );
      print('Failed to send OTP. Response: ${response.body}');
    }
  }

  // New method to confirm OTP
  Future<void> _confirmOTP() async {
    final String newPhoneNumber = _phoneController.text;
    final String otp = _otpController.text;
     final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('authToken'); // Assuming 'authToken' is the key used to store the token


    if (newPhoneNumber.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number and OTP.')),
      );
      return;
    }

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
    
      "token": userId,
      "new_phone_number": newPhoneNumber,
      "otp": otp,
    };

    // Print the request body for debugging
    print('Confirming OTP Request Body: $requestBody');

    // Send the request to the backend
    final response = await http.post(
      Uri.parse(Config.baseUrl + '/profile/confirm-otp'), // Replace with your actual backend URL for confirming OTP
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // Print the response status code for debugging
    print('Confirm OTP Response Status Code: ${response.statusCode}');

    // Handle the response
    if (response.statusCode == 200) {
      // Assuming the response contains a success message
      final responseBody = jsonDecode(response.body);
      print('Confirm OTP Response Body: $responseBody'); // Print the response body for debugging

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number updated successfully!')),
      );
      print('Phone number updated successfully.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm OTP. Status: ${response.statusCode}')),
      );
      print('Failed to confirm OTP. Response: ${response.body}');
    }
  }

  // New method to handle profile update
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      // Retrieve the user ID (token) from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('authToken'); // Assuming 'authToken' is the key used to store the token

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        return; // Exit if user ID is not found
      }

      // Prepare the data to send
      final String firstName = _firstNameController.text;
      final String lastName = _lastNameController.text;

      // Fetch the phone number from shared preferences
      final String? phoneNumber = prefs.getString('phoneNumber'); // Assuming 'phoneNumber' is the key used to store the phone number
      final String profilePicture = _profileImage != null ? _profileImage!.path : "null"; // Use the path or "null"

      // Create the request body
      final Map<String, dynamic> requestBody = {
        "token": userId, // Use the retrieved user ID
        "first_name": firstName,
        "last_name": lastName,
        "phone_number": phoneNumber ?? "+251953289595", // Use the fetched phone number or "null"
        "profile_picture": profilePicture,
      };

      // Print the request body for debugging
      print('Request Body: $requestBody');

      // Send the request to the backend
      final response = await http.post(
        Uri.parse(Config.baseUrl + '/profile/update'), // Replace with your actual backend URL
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Print the response status code for debugging
      print('Response Status Code: ${response.statusCode}');

      // Handle the response
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated!')),
        );
        print('Profile updated successfully.');
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile. Status: ${response.statusCode}')),
        );
        print('Failed to update profile. Response: ${response.body}');
      }
    } else {
      print('Form validation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _profileImage == null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        child: FaIcon(
                          FontAwesomeIcons.user,
                          size: 50,
                          color: Colors.grey.shade700,
                        ),
                      )
                    : CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_profileImage!),
                      ),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  hintText: widget.firstName,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  hintText: widget.lastName,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: widget.phoneNumber,
                  suffixIcon: isNewPhoneNumber
                      ? SizedBox(
                          width: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color.fromARGB(255, 80, 80, 80), Color.fromARGB(255, 192, 163, 197)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextButton(
                              onPressed: _sendOTP, // Call the new method to send OTP
                              child: Text('Send OTP', style: TextStyle(color: Colors.white)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: _onPhoneNumberChanged,
              ),
              SizedBox(height: 16),

              if (showOTPField)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP',
                          hintText: 'Enter OTP',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color.fromARGB(255, 80, 80, 80), Color.fromARGB(255, 192, 163, 197)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextButton(
                          onPressed: _confirmOTP, // Call the new method to confirm OTP
                          child: Text('Confirm', style: TextStyle(color: Colors.white)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF000000), Color(0xFF9A839E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ElevatedButton(
                  onPressed: _updateProfile, // Call the new method
                  child: Text(
                    'Update',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shadowColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
