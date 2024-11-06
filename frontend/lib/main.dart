import 'package:My_truck/screens/main_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'package:My_truck/screens/Driver_main_screen.dart';
// import 'screens/login_screen.dart'; // Commented out for direct navigation

void main() {
  runApp(MyApp());
}

Future<String?> getToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Initial token check - Retrieved token: $token'); // Debug print
    
    if (token != null && token.isNotEmpty) {
      print('Valid token found - Proceeding to MainAppScreen'); // Debug print
      return token;
    } else {
      print('No valid token found - Redirecting to LoginScreen'); // Debug print
      return null;
    }
  } catch (e) {
    print('Error checking token: $e'); // Debug print
    return null;
  }
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
      home: FutureBuilder<String?>(
        future: getToken(),
        builder: (context, tokenSnapshot) {
          if (tokenSnapshot.connectionState == ConnectionState.waiting) {
            print('Checking token status...'); // Debug print
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (tokenSnapshot.hasError) {
            print('Error during token check: ${tokenSnapshot.error}'); // Debug print
            return LoginScreen(); // Fallback to login screen on error
          } else if (tokenSnapshot.hasData && tokenSnapshot.data != null) {
            print('Token verification successful - Navigating to MainAppScreen'); // Debug print
            return DriverMainScreen();
          } else {
            print('No token found - Navigating to LoginScreen'); // Debug print
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
