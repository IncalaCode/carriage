import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MyLocationPage extends StatelessWidget {
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
        title: Text('My Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(FontAwesomeIcons.mapMarkerAlt, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Your Current Location',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Latitude: 9.145, Longitude: 40.4897', // Example coordinates, replace with dynamic data
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            ElevatedButton.icon(
              icon: FaIcon(FontAwesomeIcons.sync),
              label: Text('Update Location'),
              onPressed: () {
                // Call to get new location
              },
            ),
          ],
        ),
      ),
    );
  }
}
