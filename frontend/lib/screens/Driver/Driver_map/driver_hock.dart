import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;
import '../../config.dart';

class DriverHook {
  final StreamController<Map<String, dynamic>> _ordersStreamController =
      StreamController.broadcast();
  final prefs.SharedPreferences _localStorage;
  bool isLocked = false;
  Timer? _locationTimer;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_INTERVAL = Duration(seconds: 5);
  final String gebetaApiKey;

  Stream<Map<String, dynamic>> get ordersStream =>
      _ordersStreamController.stream;

  DriverHook(this._localStorage, this.gebetaApiKey);

  // Initialize with offline data if available
  Future<void> initialize() async {
    final cachedData = await _getCachedData();
    if (cachedData != null) {
      _ordersStreamController.add({
        'orders': cachedData['orders'],
        'source': 'cache',
        'message': 'Loading from cache'
      });
    }
  }

  void startPolling() {
    _locationTimer?.cancel();
    _retryTimer?.cancel();
    _retryAttempts = 0;

    _pollLocation();
  }

  Future<void> _pollLocation() async {
    try {
      Position position = await _getCurrentLocation();

      await _sendLocationUpdate(position);
      _startRegularPolling();
    } catch (e) {
      _handleError('Failed to start polling: $e');
    }
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': getToken(),
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await _processResponse(responseData, position);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('Location update failed: $e');
    }
  }

  Future<void> _processResponse(
      Map<String, dynamic> data, Position position) async {
    // Cache the latest data
    await _cacheData(data);

    // Process route if available
    if (data['route'] != null) {
      await _processRoute(data['route'], position);
    }

    // Update orders
    if (data['orders'] != null) {
      _ordersStreamController.add({
        'orders': data['orders'],
        'source': 'api',
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude
        }
      });
    }

    // Check if request is locked
    if (data['status'] == 'locked') {
      isLocked = true;
      _startRouteTracking(data['request_id']);
    }
  }

  Future<void> _processRoute(
      Map<String, dynamic> routeData, Position position) async {
    try {
      final routeResponse = await http.get(Uri.parse(
          'https://api.gebeta.app/route/v1/driving/'
          '${position.longitude},${position.latitude};'
          '${routeData['destination_longitude']},${routeData['destination_latitude']}'
          '?access_token=$gebetaApiKey'));

      if (routeResponse.statusCode == 200) {
        final routeDetails = json.decode(routeResponse.body);
        _ordersStreamController
            .add({'route': routeDetails, 'source': 'gebeta'});
      } else {
        _useOpenStreetMapFallback(position, routeData);
      }
    } catch (e) {
      _handleError('Route processing failed: $e');
      _useOpenStreetMapFallback(position, routeData);
    }
  }

  void _useOpenStreetMapFallback(
      Position position, Map<String, dynamic> routeData) {
    _ordersStreamController.add({
      'route': {
        'points': [
          [position.longitude, position.latitude],
          [
            routeData['destination_longitude'],
            routeData['destination_latitude']
          ]
        ],
        'source': 'osm'
      }
    });
  }

  Future<void> _cacheData(Map<String, dynamic> data) async {
    await _localStorage.setString(
        'driver_cache',
        json.encode(
            {'timestamp': DateTime.now().toIso8601String(), 'data': data}));
  }

  Future<Map<String, dynamic>?> _getCachedData() async {
    final cached = _localStorage.getString('driver_cache');
    if (cached != null) {
      final data = json.decode(cached);
      final timestamp = DateTime.parse(data['timestamp']);
      if (DateTime.now().difference(timestamp) < Duration(hours: 1)) {
        return data['data'];
      }
    }
    return null;
  }

  void _handleError(String error) {
    print(error);
    if (_retryAttempts < MAX_RETRIES) {
      _retryAttempts++;
      _retryTimer = Timer(RETRY_INTERVAL, _pollLocation);

      _ordersStreamController.add({
        'error': error,
        'retry_attempt': _retryAttempts,
        'max_retries': MAX_RETRIES
      });
    } else {
      _ordersStreamController.add({
        'error': 'Max retries reached',
        'message': 'Please check your connection and try again'
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _startRegularPolling() {
    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!isLocked) {
        await _pollLocation();
      }
    });
  }

  void _startRouteTracking(String requestId) {
    // Implement route tracking for locked requests
    // This could include more frequent updates and route recalculation
  }

  void stopPolling() {
    _locationTimer?.cancel();
    _retryTimer?.cancel();
    isLocked = false;
  }

  String getToken() {
    return "1"; // Replace with actual token logic
  }

  void dispose() {
    stopPolling();
    _ordersStreamController.close();
  }
}
