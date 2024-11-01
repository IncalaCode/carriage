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
            _buildOrderTile(context, 'Order #123456', 'Placed on: Jan 1, 2024', 'Delivered'),
            SizedBox(height: 10), // Space between items
            _buildOrderTile(context, 'Order #654321', 'Placed on: Jan 2, 2024', 'Shipped'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, String orderId, String date, String status) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color.fromARGB(255, 27, 47, 65), const Color.fromARGB(255, 8, 36, 63)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(FontAwesomeIcons.shoppingBag, color: Colors.white),
        title: Text(
          orderId,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          date,
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Icon(FontAwesomeIcons.arrowRight, color: Colors.white),
          ],
        ),
        onTap: () {
          // Navigate to order details
        },
      ),
    );
  }
}
