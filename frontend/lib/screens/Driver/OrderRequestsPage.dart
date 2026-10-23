import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  bool is_submit = false;

  @override
  void initState() {
    super.initState();
    _initializeHook();
  }

  Future<void> _initializeHook() async {
    final prefs = await SharedPreferences.getInstance();
    driverHook = DriverHook(context, prefs,
        'YOUR_GEBETA_API_KEY,'); // Initialize with context for message display
    await driverHook.initialize();
    await _loadStoredOrderStatuses(); // Load persisted statuses
    _fetchOrders();
    driverHook.startPolling(); // Start polling when page opens
  }

  Future<void> _loadStoredOrderStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedStatuses = prefs.getStringList('orderStatuses');
    if (storedStatuses != null) {
      setState(() {
        orderRequests = storedStatuses.map((orderData) {
          return json.decode(orderData) as Map<String, dynamic>;
        }).toList();
      });
    }
  }

  void _fetchOrders() {
    setState(() => loading = true);

    driverHook.ordersStream.listen((data) {
      // Only update the state if the widget is still mounted
      if (mounted) {
        setState(() {
          if (data['requests'] != null) {
            orderRequests = List<Map<String, dynamic>>.from(data['requests']);
            if (!orderRequests.isEmpty) {
              loading = false;
            } else {
              loading = true;
            }
          }
          if (data['message'] != null) {
            message = data['message'];
          }
        });
      }
    });
  }

  Future<void> _acceptOrder(int index, String price, String requestId) async {
    try {
      setState(() => loading = true);
      setState(() => is_submit = false);
     setState(() {
      loading = true;
        is_submit  = true;
      });

      print(price + " ${is_submit} ${requestId} " );

      await driverHook.acceptRequest(requestId, price);

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' faild to : $e')),
      );
    } finally {
      setState(() => loading = false);
      setState(() => is_submit = false);
     setState(() {
      loading = false;
      is_submit  = false;
      });
    }
  }

  Future<void> _storeOrderStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> orderData = orderRequests.map((order) {
      return json.encode(order);
    }).toList();
    await prefs.setStringList('orderStatuses', orderData);
  }

  @override
  void dispose() {
    driverHook.stopPolling(); // Stop polling when page closes
    driverHook.dispose();
    super.dispose();
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
                      order['user'],
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
                            "${order['from']} - ${order['destination']}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 100, // Ensures chip doesn't consume entire width
                      child: _buildStatusChip(
                          order['is_accepted_by_driver'] ?? ""),
                    ),
                    onTap: () {
                      if (order['is_accepted_by_driver'] == false) {
                        _showOrderDetails(context, order, index);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(bool status) {
    LinearGradient gradient;
    IconData icon;
    String label;

    if (status) {
      gradient = LinearGradient(colors: [
        const Color.fromARGB(255, 247, 176, 83),
        const Color.fromARGB(255, 244, 96, 51)
      ]);
      icon = FontAwesomeIcons.circleNotch;
      label = 'Waiting';
    } else {
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
  bool isSubmitting = false;

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
              Text('Name: ${order['user'] ?? 'Unknown'}'),
              Text(
                  'Address: ${order['from']} to ${order['destination'] ?? 'No Address'}'),
              Text('Material Type: ${order["material_type"] ?? 'Unknown'}'),
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
            is_submit
                ? Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: () {
                      if (price != null && price!.isNotEmpty) {
                        _acceptOrder(
                            index, price!, order['request_id'].toString());
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
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Order Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${order['user'] ?? 'Unknown'}'),
                Text(
                    'Address: ${order['from']} to ${order['destination'] ?? 'No Address'}'),
                Text('Material Type: ${order["material_type"] ?? 'Unknown'}'),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(labelText: 'Enter Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    price = value;
                  },
                ),
                SizedBox(height: 20),
                isSubmitting
                    ? Center(child: CircularProgressIndicator())
                    : TextButton(
                        onPressed: () {
                          if (price != null && price!.isNotEmpty) {
                            setState(() {
                              isSubmitting = true;
                            });
                            _acceptOrder(index, price!, order['request_id'].toString()).then((_) {
                          // Close the dialog after submission
                            }).catchError((error) {
                              // Handle any errors
                              setState(() {
                                isSubmitting = false;
                              });
                         ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('network error cant send ')),
                            );
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please enter a price')),
                            );
                          }
                        },
                        child: Text('Submit'),
                      ),
              ],
            ),
          );
        },
      );
    },
  );
}

}
