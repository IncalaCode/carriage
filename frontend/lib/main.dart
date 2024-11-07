import 'package:My_truck/screens/main_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'package:My_truck/screens/Driver_main_screen.dart';
// import 'screens/login_screen.dart'; // Commented out for direct navigation

void main() {
  runApp(MyApp());
}

Future<Map<String, String?>> getTokenAndUserType() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userType = prefs.getString('userType'); // Retrieve user type
    print('Initial token check - Retrieved token: $token, userType: $userType'); // Debug print
    
    if (token != null && token.isNotEmpty && userType != null) {
      print('Valid token and userType found'); // Debug print
      return {'token': token, 'userType': userType};
    } else {
      print('No valid token or userType found'); // Debug print
      return {'token': null, 'userType': null};
    }
  } catch (e) {
    print('Error checking token: $e'); // Debug print
    return {'token': null, 'userType': null};
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
      home: FutureBuilder<Map<String, String?>>(
        future: getTokenAndUserType(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Checking token status...'); // Debug print
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            print('Error during token check: ${snapshot.error}'); // Debug print
            return LoginScreen(); // Fallback to login screen on error
          } else if (snapshot.hasData && snapshot.data!['token'] != null) {
            final userType = snapshot.data!['userType'];
            if (userType == 'driver') {
              print('Driver token verification successful - Navigating to DriverMainScreen'); // Debug print
              return DriverMainScreen();
            } else if (userType == 'user') {
              print('User token verification successful - Navigating to MainAppScreen'); // Debug print
              return MainAppScreen();
            } else {
              print('Unknown userType - Navigating to LoginScreen'); // Debug print
              return LoginScreen();
            }
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
