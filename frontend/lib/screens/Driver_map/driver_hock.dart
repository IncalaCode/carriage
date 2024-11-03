import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config.dart';

class DriverHook {
  final StreamController<Map<String, dynamic>> _ordersStreamController =
      StreamController.broadcast();
  bool isLocked = false;

  Stream<Map<String, dynamic>> get ordersStream =>
      _ordersStreamController.stream;

  void startPolling() {
    int token = getToken();
    print("token: $token");

    Timer.periodic(Config.pollingInterval, (timer) async {
      if (isLocked) {
        timer.cancel(); // Stop polling if the ride is locked
        return;
      }

      try {
        // Get location or wait until available
        Position position = await _getCurrentLocation();

        // Prepare latitude and longitude for request
        double latitude = position.latitude;
        double longitude = position.longitude;

        final response = await http.post(
          Uri.parse(Config.baseUrl + "/driver/request"),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            "token": token,
            "latitude": latitude.toString(),
            "longitude": longitude.toString(),
          }),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData.containsKey("message") &&
              responseData.containsKey("0")) {
            List<Map<String, dynamic>> orders = [];

            responseData.forEach((key, value) {
              if (key != "message" && value is Map<String, dynamic>) {
                if (value['locked_user_id'] != null) {
                  isLocked = true;
                  _ordersStreamController.add({
                    "orders": [value],
                    "message": responseData["message"],
                  });
                } else {
                  orders.add(value);
                }
              }
            });

            // Add available orders to the stream if they are not locked
            if (!isLocked) {
              _ordersStreamController.add({
                "orders": orders,
                "message": responseData["message"],
              });
            }
          } else {
            print('Unexpected response format: ${response.body}');
          }
        } else {
          print('Failed to fetch orders: ${response.statusCode}');
        }
      } catch (e) {
        print('Error during polling: $e');
      }
    });
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get the current location
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void dispose() {
    _ordersStreamController.close();
  }

  int getToken() {
    return 1; // Replace with your actual token retrieval logic
  }
}
