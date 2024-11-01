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
    // Additional entries here...
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
              leading: Icon(FontAwesomeIcons.person, color: const Color.fromARGB(255, 56, 158, 241)),
              title: Text(
                order['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Row(
                children: [
                  Icon(FontAwesomeIcons.mapMarker, color: Colors.grey[700], size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['initialAddress'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              trailing: SizedBox(
                width: 100, // Ensures chip doesn't consume entire width
                child: _buildStatusChip(order['status']),
              ),
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
    LinearGradient gradient;
    IconData icon;
    String label;

    switch (status) {
      case 'waiting':
        gradient = LinearGradient(colors: [const Color.fromARGB(255, 247, 176, 83), const Color.fromARGB(255, 244, 96, 51)]);
        icon = FontAwesomeIcons.circleNotch;
        label = 'Waiting';
        break;
      case 'visited':
        gradient = LinearGradient(colors: [Colors.greenAccent, const Color.fromARGB(255, 78, 167, 81)]);
        icon = FontAwesomeIcons.checkCircle;
        label = 'Visited';
        break;
      default:
        gradient = LinearGradient(colors: [const Color.fromARGB(255, 255, 140, 140), const Color.fromARGB(255, 239, 78, 67)]);
        icon = FontAwesomeIcons.warning;
        label = 'Unvisited';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, int index) {
    String? price;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Divider(thickness: 1),
                _buildDetailTile(
                  icon: FontAwesomeIcons.person,
                  title: 'Name',
                  subtitle: order['name'],
                ),
                _buildDetailTile(
                  icon: FontAwesomeIcons.mapMarker,
                  title: 'Initial Address',
                  subtitle: order['initialAddress'],
                ),
                _buildDetailTile(
                  icon: FontAwesomeIcons.mapMarker,
                  title: 'Destination',
                  subtitle: order['destination'] ?? 'N/A',
                ),
                _buildDetailTile(
                  icon: FontAwesomeIcons.building,
                  title: 'Material Type',
                  subtitle: order['materialType'] ?? 'N/A',
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter Price',
                    prefixIcon: Icon(FontAwesomeIcons.dollarSign),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    price = value;
                  },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(FontAwesomeIcons.check),
                      label: Text('Set Price'),
                      onPressed: () {
                        if (price?.isNotEmpty ?? false) {
                          _setPrice(index, price!);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(FontAwesomeIcons.checkCircle),
                      label: Text('Visited'),
                      onPressed: () {
                        _markOrderAsVisited(index);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
