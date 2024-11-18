import 'package:My_truck/screens/User/Order_form_screen.dart';
import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyOrdersPagedriver extends StatefulWidget {
  @override
  _MyOrdersPagedriverState createState() => _MyOrdersPagedriverState();
}

class Order {
  final String status;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.status,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      status: json['status'] ?? 'Unknown Status',
      name: json['name'] ?? 'Unknown Name',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}

class _MyOrdersPagedriverState extends State<MyOrdersPagedriver> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  Future<void> getOrders() async {
    try {
            final token = getToken();


      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/getorder'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(response.body) as Map<String, dynamic>;

        if (responseBody['orders'] != null) {
          final orderData = responseBody['orders'];

          setState(() {
            if (orderData is List) {
              orders = orderData
                  .map((json) => Order.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else if (orderData is Map) {
              orders = [Order.fromJson(orderData as Map<String, dynamic>)];
            }
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
                          order.status,
                          order.name,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderTile(
      BuildContext context, String date, String status, String name) {
    // Determine the trailing icon and onTap eligibility based on order status
    IconData trailingIcon;
    bool ontap = false;

    switch (status.toLowerCase()) {
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
        leading: Icon(FontAwesomeIcons.shoppingBag, color: Colors.white),
        title: Text(
          name,
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
            Icon(trailingIcon, color: Colors.white),
          ],
        ),
        onTap: ontap
            ? () {
                print("Navigating to details of order: $name");
              }
            : null,
      ),
    );
  }
}
