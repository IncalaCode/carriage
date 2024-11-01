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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Latitude: 9.145, Longitude: 40.4897', // Example coordinates, replace with dynamic data
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Spacer(),
            ElevatedButton.icon(
              icon: FaIcon(FontAwesomeIcons.sync, color: Colors.white),
              label: Text('Update Location'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Background color (single color)
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.white, // Text and icon color
              ),
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
