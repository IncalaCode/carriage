import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyOrdersPage extends StatefulWidget {
  @override
  _MyOrdersPagedriverState createState() => _MyOrdersPagedriverState();
}

class Order {
  final String status;
  final String name;
  final String from;
  final String destination;
  final String materialType;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.status,
    required this.name,
    required this.from,
    required this.destination,
    required this.materialType,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      status: json['status'] ?? 'Unknown Status',
      name: json['name'] ?? 'Unknown Driver',
      from: json['from'] ?? 'Unknown From',
      destination: json['destination'] ?? 'Unknown Destination',
      materialType: json['material_type'] ?? 'Unknown Material',
      isOnline: (json['is_online'] == 1), // Convert integer to boolean
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}

class _MyOrdersPagedriverState extends State<MyOrdersPage> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  Future<void> getOrders() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/client/getorder'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'token': '1'}), // Adjust token handling as needed
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(response.body) as Map<String, dynamic>;

        if (responseBody['orders'] != null) {
          final orderData = responseBody['orders'];

          setState(() {
            orders = (orderData as List)
                .map((json) => Order.fromJson(json as Map<String, dynamic>))
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception('No "orders" key found in the response');
        }
      } else {
        throw Exception(
            'Failed to load orders with status code ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching orders: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('My Orders'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No orders found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: _buildOrderTile(
                          context,
                          'Placed on: ${order.createdAt.toLocal()}',
                          order,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderTile(BuildContext context, String date, Order order) {
    IconData trailingIcon;
    bool ontap = false;

    switch (order.status.toLowerCase()) {
      case 'completed':
        trailingIcon = FontAwesomeIcons.circleCheck;
        break;
      case 'cancelled':
        trailingIcon = FontAwesomeIcons.ban;
        break;
      case 'locked':
      case 'pending':
        trailingIcon = FontAwesomeIcons.arrowRight;
        ontap = true;
        break;
      default:
        trailingIcon = FontAwesomeIcons.question;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF9A839E)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(FontAwesomeIcons.truck, color: Colors.white),
        title: Row(
          children: [
            Text(
              order.name,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8), // Spacing between name and dot
            Icon(
              FontAwesomeIcons.circleDot,
              color: order.isOnline ? Colors.green : Colors.red,
              size: 10, // Size of the dot
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'From: ${order.from} - To: ${order.destination}',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Material: ${order.materialType}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Align the content to the top
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.status,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Icon(trailingIcon, color: Colors.white),
          ],
        ),
        onTap: ontap
            ? () {
                print("Navigating to details of order: ${order.name}");
              }
            : null,
      ),
    );
  }
}
