import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsPage extends StatelessWidget {
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
          ListTile(
            leading: Icon(FontAwesomeIcons.userCog),
            title: Text('Account Settings'),
            trailing: Icon(FontAwesomeIcons.arrowRight),
            onTap: () {
              // Navigate to account settings
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.bell),
            title: Text('Notification Settings'),
            trailing: Icon(FontAwesomeIcons.arrowRight),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.lock),
            title: Text('Privacy Settings'),
            trailing: Icon(FontAwesomeIcons.arrowRight),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
        ],
      ),
    );
  }
}
