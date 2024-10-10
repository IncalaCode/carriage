import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For handling file operations
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Corrected imports
import 'sidebarProfile.dart';
import 'sidebarWallet.dart';
import 'sidebarMylocation.dart';
import 'sidebarMyOrder.dart';
import 'sidebarSettings.dart';



class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  bool isDrawerOpen = false;
  File? _profileImage; // Holds the uploaded profile picture

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path); // Update profile image after picking
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        toolbarHeight: 80, // Increased height for full logo visibility
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 0), // Adjust logo's position
          child: Image.asset('assets/logo.png', height: 180), // Adjusted height for visibility
        ),
        actions: [
          // Hamburger menu icon
          Padding(
            padding: EdgeInsets.only(right: 16.0), // Aligns to the top right corner
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(FontAwesomeIcons.bars, color: Colors.white), // White hamburger icon
                onPressed: () {
                  setState(() {
                    isDrawerOpen = true; // Change state to update AppBar color
                  });
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  // Display either the uploaded profile image or person icon
                  GestureDetector(
                    onTap: _pickImage, // Pick image on tapping the icon
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: _profileImage == null
                          ? Icon(FontAwesomeIcons.user, size: 40, color: Colors.grey) // Default person icon
                          : ClipOval(
                              child: Image.file(
                                _profileImage!, // Show uploaded image
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Welcome, User!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(FontAwesomeIcons.user, 'Profile', context, () {
                    // Navigate to Profile page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()), // Corrected class name
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', context, () {
                    // Navigate to Wallet page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WalletPage()), // Corrected class name
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.mapMarkerAlt, 'My Location', context, () {
                    // Navigate to My Location page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyLocationPage()), // Corrected class name
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.shoppingCart, 'My Orders', context, () {
                    // Navigate to My Orders page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyOrdersPage()), // Corrected class name
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', context, () {
                    // Navigate to Settings page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()), // Corrected class name
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Welcome to Carriage App!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ), // Main content
      ),
    );
  }

  // Helper function for building drawer items
  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black), // Set icon color to black
      title: Text(
        title, 
        style: TextStyle(
          fontSize: 18,
          color: Colors.black, // Set text color to black for visibility
          fontWeight: FontWeight.bold,
        ),
      ),
      tileColor: Colors.grey[200], // Set background color for the list item
      onTap: () {
        onTap();
      },
    );
  }
}
