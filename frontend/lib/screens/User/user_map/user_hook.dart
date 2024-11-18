import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' as prefs;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class UserHook {
  final StreamController<Map<String, dynamic>> _driverStreamController =
      StreamController.broadcast();
  final prefs.SharedPreferences _localStorage;
  bool _isPolling = true;

  Stream<Map<String, dynamic>> get driverStream =>
      _driverStreamController.stream;

  UserHook(this._localStorage);

  // Method to start polling
  Future<void> startPolling() async {
    while (_isPolling) {
      // Fetch driver requests and add to stream
      final driverRequests = await fetchDriverRequests();
      if (!_driverStreamController.isClosed) {
        _driverStreamController.add(driverRequests);
      }

      await Future.delayed(Duration(seconds: 15));
    }
  }

  Future<dynamic> fetchDriverRequests() async {
    try {
      print("started the poling ");
      final token = await getToken(); // Retrieve token dynamically if async
      final response =
          await http.post(Uri.parse('${Config.baseUrl}/client/handle-request'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'token': token}));

      final dynamic data = json.decode(response.body);
      print(response.body);
      if (response.statusCode == 404 || response.statusCode == 401) {
        return {
          'error': data['error'] ?? 'Unknown error',
          "statusCode": response.statusCode
        };
      } else if (data['user_photo'] != null && response.statusCode == 201) {
        return {"drivers": data ?? [], "statusCode": response.statusCode};
      }
      return {
        "drivers": data['drivers'] ?? [],
        "statusCode": response.statusCode
      };
    } catch (e) {
      print('Error fetching driver requests: $e');
    }
  }

  void stoppolling() {
    _isPolling = false;
  }

  void dispose() {
    _driverStreamController.close();
    _isPolling = false;
  }

  Future getToken() async {
        final prefs = await SharedPreferences.getInstance();
        final token  = await prefs.getString('authToken');
        return token ;

  }
}
