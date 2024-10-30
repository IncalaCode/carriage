import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'sidebarProfile.dart';
import 'sidebarWallet.dart';
import 'sidebarMylocation.dart';
import 'sidebarMyOrder.dart';
import 'sidebarSettings.dart';
import './Driver_map/driver_map_component.dart';

class DriverAppScreen extends StatefulWidget {
  @override
  _DriverAppScreenState createState() => _DriverAppScreenState();
}

class _DriverAppScreenState extends State<DriverAppScreen> {
  bool isDrawerOpen = false;
  File? _profileImage;

  // A variable to hold the price entered by the driver
  String? _price;

  // Updated orderRequests to include state for each order
  List<Map<String, dynamic>> orderRequests = [
    {"name": "Jabez Hap", "initialAddress": "123 Agona St", "status": "unvisited"},
    {"name": "Yabu Des", "initialAddress": "456 Estifanos St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Yabu Des", "initialAddress": "456 Estifanos St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Jabez Hap", "initialAddress": "123 Agona St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Jabez Hap", "initialAddress": "123 Agona St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Yabu Des", "initialAddress": "456 Estifanos St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
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

  // Function to show the orders list
  void _showOrdersList() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return OrdersList(orderRequests: orderRequests, onOrderTap: _setPrice);
      },
    );
  }

  void _setPrice(int index, String price) {
    setState(() {
      orderRequests[index]['status'] = 'waithing'; // Update the status to watched
      _price = price; // Store the price if needed for further logic
    });
    Navigator.of(context).pop(); // Close the dialog
  }

  void _markOrderAsVisited(int index) {
    setState(() {
      orderRequests[index]['status'] = 'visited'; // Update the status to visited
    });
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
        toolbarHeight: 80,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Image.asset('assets/Nave.png', height: 100),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 0, right: 16.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(FontAwesomeIcons.bars, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isDrawerOpen = true;
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
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: _profileImage == null
                          ? Icon(FontAwesomeIcons.user, size: 40, color: Colors.grey)
                          : ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Hi, Driver!',
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
    DriverMapComponent(),
    Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showOrdersList,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Background color (fixed key name)
            padding: EdgeInsets.symmetric(vertical: 16), // Adjust padding for height
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
          ),
          child: Text(
            'Requests',
            style: TextStyle(
              color: Colors.white, // Text color
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    ),
        ],
      ),
    );
  }

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
      onTap: () => onTap(),
    );
  }
}

// Orders List Widget
class OrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> orderRequests; // Changed to dynamic to hold status
  final Function(int, String) onOrderTap; // Added function to handle setting price

  OrdersList({required this.orderRequests, required this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: 600,
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
                  title: Text(order['name']!),
                  subtitle: Text(order['initialAddress']!),
                  trailing: Text(order['status']!), // Display the order status
                  onTap: () {
                    _showOrderDetails(context, order, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, int index) {
    String? price;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${order['name']}'),
              Text('Initial Address: ${order['initialAddress']}'),
              Text('destination: ${order['destination']}'),
              Text('Material Type: ${order['materialType']}'),
              Text('Status: ${order['status']}'), // Show current status
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(labelText: 'Enter Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  price = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (price != null && price!.isNotEmpty) {
                  onOrderTap(index, price!); // Call the function to set the price and update the order
                  Navigator.of(context).pop();
                } else {
                  // Handle case when price is not entered
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a price')),
                  );
                }
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                // Mark order as visited
                Navigator.of(context).pop();
              },
              child: Text('Mark as Visited'),
            ),
          ],
        );
      },
    );
  }
}
