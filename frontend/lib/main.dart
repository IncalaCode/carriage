import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
// import 'screens/map_service.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carraige App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSans', 
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),  // Show the splash screen first
    );
  }
}
