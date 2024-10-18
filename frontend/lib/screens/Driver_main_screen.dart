import 'package:flutter/material.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For Google Maps
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; 
import 'sidebarProfile.dart';
import 'sidebarWallet.dart';
import 'sidebarMylocation.dart';
import 'sidebarMyOrder.dart';
import 'sidebarSettings.dart';

class DriverAppScreen extends StatefulWidget {
  @override
  _DriverAppScreenState createState() => _DriverAppScreenState();
}

class _DriverAppScreenState extends State<DriverAppScreen> {
  bool isDrawerOpen = false;
  File? _profileImage;
  GoogleMapController? mapController;
  final LatLng _initialPosition = LatLng(37.7749, -122.4194); // San Francisco coordinates

  List<Map<String, String>> orderRequests = [
    {"name": "Jabez Hap", "initialAddress": "123 Agona St"},
    {"name": "Yabu Des", "initialAddress": "456 Estifanos St"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St"},
  ];
  
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

  // Function to show the orders list
  void _showOrdersList() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return OrdersList(orderRequests: orderRequests);
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
        toolbarHeight: 80, // Increased height for full logo visibility
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 50), // Adjust logo's position
          child: Image.asset('assets/Nave.png', height: 100), // Adjusted height for visibility
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 0, right: 16.0), // Aligns to the top right corner
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
                    'Welcome, Driver!',
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
          // "Requests" button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showOrdersList,
              backgroundColor: Colors.blueAccent,
              child: Text(
                'Requests',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Increased size
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
        style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      tileColor: Colors.grey[200],
      onTap: () {
        onTap();
      },
    );
  }
}

// Orders List Widget
class OrdersList extends StatelessWidget {
  final List<Map<String, String>> orderRequests;

  OrdersList({required this.orderRequests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: 600, // Adjust height as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: orderRequests.length,
              itemBuilder: (context, index) {
                final order = orderRequests[index];
                return ListTile(
                  title: Text(order['name']!), // Updated to "name"
                  subtitle: Text(order['initialAddress']!),
                  onTap: () {
                    _showOrderDetails(context, order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, String> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${order['name']}'), // Updated "First Name" to "Name"
              Text('Initial Address: ${order['initialAddress']}'),
              Text('Destination: ${order['destination'] ?? "Unknown"}'),
              Text('Material Type: ${order['materialType'] ?? "General"}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Accept'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
