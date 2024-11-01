import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OrderRequestsPage extends StatefulWidget {
  @override
  _OrderRequestsPageState createState() => _OrderRequestsPageState();
}

class _OrderRequestsPageState extends State<OrderRequestsPage> {
  List<Map<String, dynamic>> orderRequests = [
    {"name": "Jabez Hap", "initialAddress": "123 Agona St", "status": "unvisited"},
    {"name": "Yabu Des", "initialAddress": "456 Estifanos St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Yabets Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Abdelrahman Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Bassem Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Hussein Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Muse Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Youssef Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
    {"name": "Begeta Desalegn", "initialAddress": "789 B.MEdhanialem St", "status": "unvisited"},
  ];

  void _setPrice(int index, String price) {
    setState(() {
      orderRequests[index]['status'] = 'waiting';
      orderRequests[index]['price'] = price;
    });
  }

  void _markOrderAsVisited(int index) {
    setState(() {
      orderRequests[index]['status'] = 'visited';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Requests"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: orderRequests.length,
        itemBuilder: (context, index) {
          final order = orderRequests[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                order['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                order['initialAddress'],
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              trailing: _buildStatusChip(order['status']),
              onTap: () {
                _showOrderDetails(context, order, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    List<Color> gradientColors;
    String label;

    switch (status) {
      case 'waiting':
        gradientColors = [Colors.orange, Colors.yellow]; // Gradient for waiting
        label = 'Waiting';
        break;
      case 'visited':
        gradientColors = [Colors.green, const Color.fromARGB(255, 152, 201, 95)]; // Gradient for visited
        label = 'Visited';
        break;
      default:
        gradientColors = [Colors.red, const Color.fromARGB(255, 253, 144, 144)]; // Gradient for unvisited
        label = 'Unvisited';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white),
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
              Text('materialType: ${order['materialType']}'),
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
                if (price?.isNotEmpty ?? false) {
                  _setPrice(index, price!);
                  Navigator.pop(context);
                }
              },
              child: Text('Set Price'),
            ),
            TextButton(
              onPressed: () {
                _markOrderAsVisited(index);
                Navigator.pop(context);
              },
              child: Text('Visited'),
            ),
          ],
        );
      },
    );
  }
}
