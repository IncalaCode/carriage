import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io'; // For file handling (image upload)
import 'package:image_picker/image_picker.dart'; // For image picking
import 'sidebarProfileEdit.dart';

// Edit profile page
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context); // Back functionality
          },
        ),
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.userEdit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
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
            // Profile Image
            GestureDetector(
              onTap: _pickImage, // Tap to upload image
              child: _profileImage == null
                  ? CircleAvatar(
                      radius: 50,
                      child: Icon(
                        FontAwesomeIcons.user,
                        size: 50,
                      ),
                    )
                  : Container(
                      width: double.infinity, // Full width of the screen
                      height: MediaQuery.of(context).size.height * 0.4, // Half of the screen height
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover, // Make image cover the entire half-screen
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 20),

            // Full Name
            Row(
              children: [
                FaIcon(FontAwesomeIcons.user, size: 20, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  'Jabez Hap',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Email
            Row(
              children: [
                FaIcon(FontAwesomeIcons.envelope, size: 20, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  'Jabez@gmail.com',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Phone Number
            Row(
              children: [
                FaIcon(FontAwesomeIcons.phone, size: 20, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  '+251 963 488 972',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            Spacer(),

            // Logout Button
            ElevatedButton.icon(
              icon: FaIcon(FontAwesomeIcons.signOutAlt),
              label: Text('Logout'),
              onPressed: () {
                // Navigate to Login page after logout
                Navigator.pushReplacementNamed(context, 'LoginScreen');
              },
            ),
          ],
        ),
      ),
    );
  }
}