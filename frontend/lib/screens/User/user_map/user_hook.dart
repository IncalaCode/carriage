import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' as prefs;
import '../../config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UserHook {
  final StreamController<Map<String, dynamic>> _driverStreamController =
      StreamController.broadcast();
  final prefs.SharedPreferences _localStorage;
  bool isTracking = false;
  Timer? _locationTimer;
  final String gebetaApiKey;
  MapController mapController = MapController();

  Stream<Map<String, dynamic>> get driverStream =>
      _driverStreamController.stream;

  UserHook(this._localStorage, this.gebetaApiKey);

  // Start tracking driver location
  void startTracking(int driverId) async {
    isTracking = true;
    _startLocationPolling(driverId);
  }

  void _startLocationPolling(int driverId) {
    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!isTracking) {
        timer.cancel();
        return;
      }

      try {
        final response = await http.post(
            Uri.parse('${Config.baseUrl}/client/handle-request'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'token': getToken(),
            }));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await _updateDriverLocation(data);
          await _cacheLocationData(data);
          await _calculateETA(data);
        } else {
          // Fallback to cached data
          final cachedData = await _getCachedLocationData();
          if (cachedData != null) {
            _driverStreamController.add({
              'location': cachedData,
              'source': 'cache',
              'message': 'Using cached data'
            });
          }
        }
      } catch (e) {
        print('Error tracking driver: $e');
        _handleApiFailure();
      }
    });
  }

  Future<void> _updateDriverLocation(Map<String, dynamic> data) async {
    if (data['latitude'] != null && data['longitude'] != null) {
      // Check driver online status
      bool isOnline = await _checkDriverOnline(data);
      if (!isOnline) {
        _notifyDriverOffline();
        return;
      }

      // Update map with Gebeta Maps
      try {
        final routeResponse =
            await http.get(Uri.parse('https://api.gebeta.app/route/v1/driving/'
                '${data['from_longitude']},${data['from_latitude']};'
                '${data['to_longitude']},${data['to_latitude']}'
                '?access_token=$gebetaApiKey'));

        if (routeResponse.statusCode == 200) {
          final routeData = json.decode(routeResponse.body);
          _driverStreamController
              .add({'location': data, 'route': routeData, 'source': 'api'});
        }
      } catch (e) {
        // Fallback to OpenStreetMap
        _useOpenStreetMapFallback(data);
      }
    }
  }

  Future<void> _cacheLocationData(Map<String, dynamic> data) async {
    await _localStorage.setString('last_known_location', json.encode(data));
  }

  Future<Map<String, dynamic>?> _getCachedLocationData() async {
    final cached = _localStorage.getString('last_known_location');
    return cached != null ? json.decode(cached) : null;
  }

  Future<void> _calculateETA(Map<String, dynamic> data) async {
    try {
      final matrixResponse =
          await http.get(Uri.parse('https://api.gebeta.app/matrix/v1/driving/'
              '${data['from_longitude']},${data['from_latitude']};'
              '${data['to_longitude']},${data['to_latitude']}'
              '?access_token=$gebetaApiKey'));

      if (matrixResponse.statusCode == 200) {
        final etaData = json.decode(matrixResponse.body);
        _driverStreamController
            .add({'eta': etaData['durations'][0][1], 'source': 'api'});
      }
    } catch (e) {
      print('Error calculating ETA: $e');
    }
  }

  void _useOpenStreetMapFallback(Map<String, dynamic> data) {
    // Implement OpenStreetMap fallback
    final points = [
      LatLng(double.parse(data['from_latitude']),
          double.parse(data['from_longitude'])),
      LatLng(
          double.parse(data['to_latitude']), double.parse(data['to_longitude']))
    ];

    _driverStreamController
        .add({'location': data, 'points': points, 'source': 'osm'});
  }

  void _handleApiFailure() async {
    final cachedData = await _getCachedLocationData();
    if (cachedData != null) {
      _driverStreamController.add({
        'location': cachedData,
        'source': 'cache',
        'message': 'Using cached data due to API failure'
      });
    }
  }

  void stopTracking() {
    isTracking = false;
    _locationTimer?.cancel();
  }

  void dispose() {
    stopTracking();
    _driverStreamController.close();
  }

  String getToken() {
    return "1"; // Replace with actual token logic
  }

  // Check driver online status
  Future<bool> _checkDriverOnline(Map<String, dynamic> data) async {
    final lastUpdate = DateTime.parse(data['last_active']);
    final difference = DateTime.now().difference(lastUpdate);
    return difference.inMinutes < 5; // 5 minutes threshold
  }

  void _notifyDriverOffline() {
    _driverStreamController.add({
      'status': 'offline',
      'message': 'Driver is currently offline',
      'source': 'status_check'
    });
  }
}
