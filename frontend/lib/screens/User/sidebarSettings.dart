import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // State variable for notification switch

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
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildDeleteAccountTile(context),
          Divider(),
          _buildNotificationSettingsTile(),
        ],
      ),
    );
  }

  // Build the Delete Account tile with confirmation dialog
  Widget _buildDeleteAccountTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF9A839E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(FontAwesomeIcons.trash, color: Colors.white), // Changed icon to trash
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Warning'),
                content: Text('Are you sure do you want to delete this account?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacementNamed(context, '/login'); // Go to login page
                    },
                    child: Text('Yes'),
                  ),
                ],
              );
            },
          );
        },
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    );
  }

  // Build the Notification Settings tile with toggle switch
  Widget _buildNotificationSettingsTile() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF9A839E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(FontAwesomeIcons.bell, color: Colors.white),
        title: Text(
          'Notification Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Switch(
          value: _notificationsEnabled, // Bind to state variable
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value; // Update state when switch is toggled
            });
          },
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    );
  }
}
