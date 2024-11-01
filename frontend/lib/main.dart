import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
// import 'screens/map_service.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'screens/PaymentPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carriage App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSans',
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Show the splash screen first
    );
  }
}

// Function to initiate user payment
void initiateUserPayment(BuildContext context) {
  final chapaUserPaymentUrl = 'https://api.chapa.co/v1/user-payment-url'; // Replace with actual Chapa URL

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentPage(chapaPaymentUrl: chapaUserPaymentUrl),
    ),
  ).then((result) {
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  });
}

// Function to initiate driver payment
void initiateDriverPayment(BuildContext context) {
  final chapaDriverPaymentUrl = 'https://api.chapa.co/v1/driver-payment-url'; // Replace with actual Chapa URL

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentPage(chapaPaymentUrl: chapaDriverPaymentUrl),
    ),
  ).then((result) {
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  });
}
