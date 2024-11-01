import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

Future<void> submitOrderForm({
  required BuildContext context,
  required String from,
  required String destination,
  required String materialType,
  required String carType,
}) async {
  try {
    // Construct the request payload
    final payload = {
      "from": from,
      "destination": destination,
      "materialType": materialType,
      "carType": carType,
    };

    // Make the POST request
    final response = await http.post(
       Uri.parse(Config.baseUrl + "/driver/request"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    // Handle the response
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request submitted successfully!')),
      );
    } else {
      // Decode error message from the server response
      final error = jsonDecode(response.body)["message"] ?? "Something went wrong.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  } catch (error) {
    // Handle network or decoding errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: ${error.toString()}')),
    );
  }
}
