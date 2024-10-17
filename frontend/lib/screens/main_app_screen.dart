import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For handling file operations
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For Google Maps

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
  GoogleMapController? mapController;
  final LatLng _initialPosition = LatLng(37.7749, -122.4194); // San Francisco coordinates

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path); // Update profile image after picking
      });
    }
  }

  // Function to handle Google Map creation
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Function to show the order form
  void _showOrderForm() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return OrderForm();
      },
    );
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
        toolbarHeight:100, // Increased height for full logo visibility
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 0), // Adjust logo's position
          child: Image.asset('assets/logo.png', height: 180), // Adjusted height for visibility
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only( top: 0,right: 16.0), // Aligns to the top right corner
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', context, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WalletPage()),
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.mapMarkerAlt, 'My Location', context, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyLocationPage()),
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.shoppingCart, 'My Orders', context, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyOrdersPage()),
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', context, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Google Map integration
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12.0,
            ),
            mapType: MapType.normal,
          ),
          // "Order Now" button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showOrderForm, // Show order form when pressed
              backgroundColor: Colors.blueAccent,
              child: Text(
                'Order\nNow',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for building drawer items
  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      tileColor: Colors.grey[200],
      onTap: () {
        onTap();
      },
    );
  }
}

// New Order Form Widget
class OrderForm extends StatelessWidget {
  final TextEditingController FromController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController materialTypeController = TextEditingController();
  final TextEditingController BirrController = TextEditingController();
  String? loadType;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Order Form',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: FromController,
            decoration: InputDecoration(labelText: 'From(መነሻ )'),
          ),
          TextField(
            controller: destinationController,
            decoration: InputDecoration(labelText: 'Destination(መድረሻ )'),
          ),
          TextField(
            controller: materialTypeController,
            decoration: InputDecoration(labelText: 'Material Type(የሚጓጓዘው እቃ አይነት )'),
          ),
          TextField(
            controller: materialTypeController,
            decoration: InputDecoration(labelText: 'Birr'),
          ),
          
          DropdownButton<String>(
            hint: Text('Select Load Type'),
            value: loadType,
            onChanged: (String? newValue) {
              loadType = newValue;
            },
            items: <String>['Half Load', 'Full Load']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle the order submission logic here
              String From = FromController.text;
              String destination = destinationController.text;
              String materialType = materialTypeController.text;
              String Birr = BirrController.text;

              // Use loadType variable
              print('Order submitted: From - $From, Destination - $destination, Material Type - $materialType, Load Type - $loadType, Birr - $Birr');
              Navigator.pop(context); // Close the form after submission
            },
            child: Text('Request'),
          ),
        ],
      ),
    );
  }
}
