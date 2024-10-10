import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MyOrdersPage extends StatelessWidget {
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
        title: Text('My Orders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(FontAwesomeIcons.shoppingBag),
              title: Text('Order #123456'),
              subtitle: Text('Placed on: Jan 1, 2024'),
              trailing: Icon(FontAwesomeIcons.arrowRight),
              onTap: () {
                // Navigate to order details
              },
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.shoppingBag),
              title: Text('Order #654321'),
              subtitle: Text('Placed on: Jan 2, 2024'),
              trailing: Icon(FontAwesomeIcons.arrowRight),
              onTap: () {
                // Navigate to order details
              },
            ),
          ],
        ),
      ),
    );
  }
}
