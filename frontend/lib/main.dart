import 'package:My_truck/screens/main_app_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
// import 'screens/login_screen.dart'; // Commented out for direct navigation
import 'screens/PaymentPage.dart';

void main() {
  runApp(MyApp());
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Truck',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSans',
      ),
      debugShowCheckedModeBanner: false,
      // Directly navigate to SplashScreen for testing; change back to LoginScreen() after testing
      // home: SplashScreen(),

      home: FutureBuilder<String?>(
        future: getToken(),
        builder: (context, tokenSnapshot) {
          if (tokenSnapshot.connectionState == ConnectionState.waiting) {
            // Display a loading indicator while waiting for the future to complete
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (tokenSnapshot.hasData && tokenSnapshot.data != null) {
            // If a token exists, go to MainAppScreen
            return MainAppScreen();
          } else {
            // If no token, go to LoginScreen
            return LoginScreen();
          }
        },
      ),
    );

    //      home: MainAppScreen(),
    //      home: LoginScreen(), // Uncomment this line to restore login navigation
  }
}

// Function to initiate user payment
// void initiateUserPayment(BuildContext context) {
//   final chapaUserPaymentUrl = 'https://api.chapa.co/v1/user-payment-url'; // Replace with actual Chapa URL

//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => PaymentPage(chapaPaymentUrl: chapaUserPaymentUrl),
//     ),
//   ).then((result) {
//     if (result != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
//     }
//   });
// }

// // Function to initiate driver payment
// void initiateDriverPayment(BuildContext context) {
//   final chapaDriverPaymentUrl = 'https://api.chapa.co/v1/driver-payment-url'; // Replace with actual Chapa URL

//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => PaymentPage(chapaPaymentUrl: chapaDriverPaymentUrl),
//     ),
//   ).then((result) {
//     if (result != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
//     }
//   });
// }
