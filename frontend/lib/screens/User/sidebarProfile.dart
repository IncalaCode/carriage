import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'sidebarProfileEdit.dart';
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String _firstName = 'Jabez'; // Default value
  String _lastName = 'Hap'; // Default value
  String _phoneNumber = '+251 963 488 972'; // Default value
  String _firstName = ''; // Default value
  String _lastName = ''; // Default value
  String _phoneNumber = ''; // Default value

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the profile page is initialized
  }

  // New method to fetch user data
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('authToken'); // Assuming 'authToken' is the key used to store the token

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      return; // Exit if user ID is not found
    }

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      "token": userId,
    };

    // Send the request to the backend
    final response = await http.post(
      Uri.parse(Config.baseUrl + '/profile'), // Replace with your actual backend URL for fetching user data
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // Print the response status code for debugging
    print('Fetch User Data Response Status Code: ${response.statusCode}');

    // Handle the response
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Fetch User Data Response Body: $responseBody'); // Print the response body for debugging

      // Update the state with the fetched data
      setState(() {
        _firstName = responseBody['first_name'] ?? 'Jabez'; // Update with fetched first name
        _lastName = responseBody['last_name'] ?? 'Hap'; // Update with fetched last name
        _phoneNumber = responseBody['phone_number'] ?? '+251 963 488 972'; // Update with fetched phone number
        _firstName = responseBody['first_name'] ?? ''; // Update with fetched first name
        _lastName = responseBody['last_name'] ?? ''; // Update with fetched last name
        _phoneNumber = responseBody['phone_number'] ?? ''; // Update with fetched phone number
        String profilePicturePath = responseBody['profile_picture'] ?? ''; // Update with fetched profile picture path
        if (profilePicturePath.isNotEmpty) {
          _profileImage = File(profilePicturePath); // Load the profile image if available
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data. Status: ${response.statusCode}')),
      );
      print('Failed to fetch user data. Response: ${response.body}');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete token and navigate to login screen
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear all stored shared preferences
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF000000),
                      Color(0xFF9A839E)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ],
        );
      },
    );
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
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.userEdit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    profileImage: _profileImage,
                    firstName: _firstName,
                    lastName: _lastName,
                    phoneNumber: _phoneNumber,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? Icon(
                        FontAwesomeIcons.user,
                        size: 50,
                        color: const Color.fromARGB(255, 52, 52, 52),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_firstName $_lastName', // Use fetched name
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.phone, size: 20, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        _phoneNumber, // Use fetched phone number
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Spacer(),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000000),
                    Color(0xFF9A839E)
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ElevatedButton.icon(
                icon: FaIcon(FontAwesomeIcons.signOutAlt, color: Colors.white),
                label: Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: _showLogoutConfirmation,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
