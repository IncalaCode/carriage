import 'package:My_truck/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
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
      home: LoginScreen(),  // Show the splash screen first
    );
  }
}
