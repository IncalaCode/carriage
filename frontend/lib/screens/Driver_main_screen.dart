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
import './Driver_map/driver_hock.dart';

class DriverAppScreen extends StatefulWidget {
  @override
  _DriverAppScreenState createState() => _DriverAppScreenState();
}

class _DriverAppScreenState extends State<DriverAppScreen> {
  bool isDrawerOpen = false;
  bool loading = true; // Loading state
  File? _profileImage;
  String? _price;
  String message = ''; // Store the message
  final DriverHook driverHook = DriverHook();
  List<Map<String, dynamic>> orderRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders(); // Fetch orders on init
  }

  void _fetchOrders() async {
    setState(() => loading = true); // Start loading
    driverHook.startPolling();
    driverHook.ordersStream.listen((data) {
      setState(() {
        orderRequests = List<Map<String, dynamic>>.from(data['orders']);
        message = data['message'];
        loading = false; // Stop loading when orders are fetched
      });
    });
  }

void _showOrdersList() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return OrdersList(
        orderRequests: orderRequests,
        onOrderTap: _setPrice,
        loading: loading,
        showOrderDetails: _showOrderDetails,
        message: message, // Pass the message
      );
    },
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
              Text('Name: ${order['name'] ?? 'Unknown'}'),
              Text('Address: ${order['initialAddress'] ?? 'No Address'}'),
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
                  _setPrice(index, price!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a price')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    driverHook.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _setPrice(int index, String price) {
    setState(() {
      orderRequests[index]['status'] = 'waiting';
      _price = price;
    });
    Navigator.of(context).pop();
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
                  setState(() => isDrawerOpen = true);
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WalletPage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.mapMarkerAlt, 'My Location', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyLocationPage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.shoppingCart, 'My Orders', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersPage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
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
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _showOrdersList,
              backgroundColor: Colors.transparent,
              icon: Icon(FontAwesomeIcons.bell, color: Colors.white),
              label: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color.fromARGB(255, 0, 0, 0), const Color.fromARGB(255, 75, 75, 75)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Requests',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
class OrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> orderRequests;
  final Function(int, String) onOrderTap;
  final bool loading;
  final Function(BuildContext, Map<String, dynamic>, int) showOrderDetails; // New parameter
  final String message; // Message from the backend

  OrdersList({
    required this.orderRequests,
    required this.onOrderTap,
    required this.loading,
    required this.showOrderDetails,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Container to hold loading indicator or message at the top
    return Column(
      children: [
      if (loading) ...[
  // Loading indicator when polling
  Center(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message.isNotEmpty ? message : 'Searching for Requests...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

            // Padding for the CircularProgressIndicator
            Padding(
                padding: const EdgeInsets.all(8.0), // Padding between text and loading indicator
              child: SizedBox(
                width: 20, // Width of the CircularProgressIndicator
                height: 20, // Height of the CircularProgressIndicator
                child: CircularProgressIndicator(strokeWidth: 2), // Reduced stroke width
              ),
            ),
          ],
        ),
        SizedBox(height: 10), // Space below the row
        Divider(), // Line to separate loading/message from the order list
      ],
    ),
  ),
] else if (message.isNotEmpty) ...[
          // If there's a message from the backend
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Divider(), // Line to separate message from the order list
        ],

        // If there are orders
        if (orderRequests.isNotEmpty) ...[
          Expanded(
            child: ListView.builder(
              itemCount: orderRequests.length,
              itemBuilder: (context, index) {
                final order = orderRequests[index];
                return ListTile(
                  title: Text(order['name'] ?? 'Unknown'),
                  subtitle: Text(order['initialAddress'] ?? 'No Address'),
                  trailing: Text(order['status'] ?? 'Unknown'),
                  onTap: () {
                    showOrderDetails(context, order, index); // Use the callback
                  },
                );
              },
            ),
          ),
        ] else ...[
          // If no orders are available
          Center(
            child: Text(
              'No Requests Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}
