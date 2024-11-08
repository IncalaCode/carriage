import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../config.dart';

class DriverHook {
  final StreamController<Map<String, dynamic>> _ordersStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final prefs.SharedPreferences _localStorage;
  final BuildContext context;
  bool isLocked = false;
  Timer? _locationTimer;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_INTERVAL = Duration(seconds: 5);
  final String gebetaApiKey;
  static bool is_active = false;
  bool isStreamPaused = false;
  late StreamSubscription<Map<String, dynamic>> _streamSubscription;

  Stream<Map<String, dynamic>> get ordersStream =>
      _ordersStreamController.stream;

  DriverHook(this.context, this._localStorage, this.gebetaApiKey);
//  Initialize with offline data if available and load environment variables
  Future<void> initialize() async {
    await dotenv.load(); // Load environment variables
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
    resumeStream();
    // Start polling immediately and then set regular intervals
    _retryAttempts = 0;
    _locationTimer?.cancel();
    _startRegularPolling(); // Schedule regular polling
  }

  Future<void> _pollLocation() async {
    try {
      await createRequest_getrequest();
    } catch (e) {
      _handleError('Failed to start polling: $e');
    }
  }

  // Method to create a request
  Future<void> createRequest_getrequest() async {
    try {
      Position position = await _getCurrentLocation();
      print("started polling");
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': getToken(),
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
      );

      if (response.statusCode != 200) {
        _handleError('Request creation failed:');
      }
      final data = json.decode(response.body);
      if (data.containsKey('locked') && data['locked'] == true) {
        _startRouteTracking(data['request_id']);
        isLocked = true;
      } else {
        _handleNewRequests(data);
      }
    } catch (e) {
      _handleError('Request creation failed: $e');
    }
  }

  // Method to accept a request
  Future<void> acceptRequest(String requestId, String price) async {
    try {
      Position position = await _getCurrentLocation();
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_request_id": requestId,
          "price": price,
          'token': getToken(),
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
      );

      if (response.statusCode != 200) {
        _showMessage('Request sent failed');
        return;
      }

      final data = json.decode(response.body);
      _handleNewRequests(data);
      _showMessage('Request sent successfully!');
    } catch (e) {
      final errorMsg = 'Request sent failed: $e';
      print(errorMsg);
      _showMessage(errorMsg);
    }
  }

  // Method to complete a request
  Future<void> completeRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requestId': requestId}),
      );

      if (response.statusCode == 200) _handleError('Request creation failed: ');
      final data = json.decode(response.body);
      _handleRideAcceptance(data);
    } catch (e) {
      _handleError('Request completion failed: $e');
    }
  }

  // Method to cancel a request
  Future<void> cancelRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requestId': requestId}),
      );
      final data = json.decode(response.body);
      _handleRideAcceptance(data);
    } catch (e) {
      _handleError('Request cancellation failed: $e');
    }
  }

  void _handleNewRequests(Map<String, dynamic> data) async {
    if (!_ordersStreamController.isClosed) {
      _ordersStreamController.add({
        'requests': data['requests'],
        'source': 'api',
        'message': data['message'],
      });
    } else {
      print("StreamController is closed; can't add new requests.");
    }
  }

  void _handleActiveRequest(Map<String, dynamic> data) {
    _ordersStreamController.add({
      'active_request': data['current_request'],
      'next_action': data['next_action'],
      'message': data['message']
    });
  }

  void _handleRideAcceptance(Map<String, dynamic> data) {
    _ordersStreamController.add({
      'requests': data['requests'],
      'status': 'accepted',
    });
  }

  void _handleCompletionRequest(Map<String, dynamic> data) {
    _ordersStreamController.add({
      'message': data['message'],
      'status': 'awaiting_confirmation',
    });
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied)
      throw Exception('Location permissions are denied');
    if (permission == LocationPermission.deniedForever)
      throw Exception('Location permissions are permanently denied');

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _startRegularPolling() async {
    await _pollLocation();
    _locationTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      if (!isLocked) await _pollLocation();
    });
  }

  void _startRouteTracking(String requestId) {
    // Implement route tracking logic
  }

  void _handleError(String error) {
    print(error);
    if (!_ordersStreamController.isClosed) {
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
  }

  Future<Map<String, dynamic>?> _getCachedData() async {
    final cached = _localStorage.getString('driver_cache');
    if (cached != null) {
      final data = json.decode(cached);
      final timestamp = DateTime.parse(data['timestamp']);
      if (DateTime.now().difference(timestamp) < Duration(hours: 1))
        return data['data'];
    }
    return null;
  }

  String getToken() => "1w"; // Replace with actual token logic

  void dispose() {
    stopPolling();
    pauseStream();
  }

  void stopPolling() {
    _locationTimer?.cancel();
    _retryTimer?.cancel();
    isLocked = false;
  }

  // Pause the stream using the StreamSubscription
  void pauseStream() {
    if (!_streamSubscription.isPaused) {
      // Check if the stream is not already paused
      _streamSubscription.pause(); // Directly call pause
      isStreamPaused = true;
      print("Stream paused.");
    }
  }

  // Resume the stream using the StreamSubscription
  void resumeStream() {
    if (isStreamPaused) {
      // Check if the stream is paused
      _streamSubscription.resume(); // Directly call resume
      isStreamPaused = false;
      print("Stream resumed.");
    }
  }

  // Helper function to show messages on the screen
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
