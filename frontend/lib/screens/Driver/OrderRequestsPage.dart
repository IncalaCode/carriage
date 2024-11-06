import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Driver_map/driver_hock.dart';

class OrderRequestsPage extends StatefulWidget {
  @override
  _OrderRequestsPageState createState() => _OrderRequestsPageState();
}

class _OrderRequestsPageState extends State<OrderRequestsPage> {
  String? _price;
  String message = '';
  late DriverHook driverHook;
  List<Map<String, dynamic>> orderRequests = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _initializeHook();
  }

  Future<void> _initializeHook() async {
    final prefs = await SharedPreferences.getInstance();
    driverHook = DriverHook(prefs, 'YOUR_GEBETA_API_KEY');
    _fetchOrders();
  }

  void _fetchOrders() {
    setState(() => loading = true);
    driverHook.startPolling();
    driverHook.ordersStream.listen((data) {
      setState(() {
        if (data['orders'] != null) {
          orderRequests = List<Map<String, dynamic>>.from(data['orders']);
        }
        if (data['message'] != null) {
          message = data['message'];
        }
        loading = false;
      });
    });
  }

  Future<void> _acceptOrder(int index, String price) async {
    try {
      setState(() => loading = true);

      // Update UI immediately
      setState(() {
        orderRequests[index]['status'] = 'waiting';
        orderRequests[index]['price'] = price;
      });

      // Close price input dialog
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to accept order: $e')));
    } finally {
      setState(() => loading = false);
    }
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
      body: loading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : ListView.builder(
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
                    leading: Icon(FontAwesomeIcons.person,
                        color: const Color.fromARGB(255, 56, 158, 241)),
                    title: Text(
                      order['name'],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(FontAwesomeIcons.mapMarker,
                            color: Colors.grey[700], size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order['initialAddress'],
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
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
        gradient = LinearGradient(colors: [
          const Color.fromARGB(255, 247, 176, 83),
          const Color.fromARGB(255, 244, 96, 51)
        ]);
        icon = FontAwesomeIcons.circleNotch;
        label = 'Waiting';
        break;
      case 'visited':
        gradient = LinearGradient(colors: [
          Colors.greenAccent,
          const Color.fromARGB(255, 78, 167, 81)
        ]);
        icon = FontAwesomeIcons.checkCircle;
        label = 'Visited';
        break;
      default:
        gradient = LinearGradient(colors: [
          const Color.fromARGB(255, 255, 140, 140),
          const Color.fromARGB(255, 239, 78, 67)
        ]);
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

  void _showOrderDetails(
      BuildContext context, Map<String, dynamic> order, int index) {
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
              Text('Name: ${order['name'] ?? 'Unknown'}'),
              Text('Address: ${order['initialAddress'] ?? 'No Address'}'),
              SizedBox(height: 20),
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
                if (price != null && price!.isNotEmpty) {
                  _acceptOrder(index, price!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a price')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    driverHook.dispose();
    super.dispose();
  }
}
