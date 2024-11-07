import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsPagedriver extends StatelessWidget {
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
          _buildSettingsTile(
            context,
            FontAwesomeIcons.userCog,
            'Delete Account',
            onTap: () {
              // Navigate to account settings
            },
          ),
          Divider(),
          _buildSettingsTile(
            context,
            FontAwesomeIcons.bell,
            'Notification Settings',
            onTap: () {
              // Navigate to notification settings
            },
          ),
          Divider(),
          _buildSettingsTile(
            context,
            FontAwesomeIcons.lock,
            'Privacy Settings',
            onTap: () {
              // Navigate to privacy settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
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
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Icon(FontAwesomeIcons.arrowRight, color: Colors.white),
        onTap: onTap,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    );
  }
}
