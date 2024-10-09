import 'package:flutter/material.dart';

class MainAppScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Removes shadow under the AppBar for a cleaner look
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0), // Adjusts logo's top margin
              child: Image.asset('assets/logo.png', height: 200), // Reduced logo height
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0, top: 16.0), // Aligns to top right corner
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white), // White menu icon
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Correct context for opening the drawer
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
                color: Colors.indigo, // Matches the app bar for consistency
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/profile_picture.png'), // Profile picture
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
                  _buildDrawerItem(Icons.person, 'Profile', context, () {
                    // Navigate to Profile
                  }),
                  _buildDrawerItem(Icons.account_balance_wallet, 'Wallet', context, () {
                    // Navigate to Wallet
                  }),
                  _buildDrawerItem(Icons.location_on, 'My Location', context, () {
                    // Navigate to My Location
                  }),
                  _buildDrawerItem(Icons.shopping_cart, 'My Orders', context, () {
                    // Navigate to Orders
                  }),
                  _buildDrawerItem(Icons.settings, 'Settings', context, () {
                    // Navigate to Settings
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Welcome to Carraige App!',
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
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title, style: TextStyle(fontSize: 18)),
      onTap: () {
        onTap();
      },
    );
  }
}
