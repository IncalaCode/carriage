import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './user_hook.dart';

class UserMapComponent extends StatefulWidget {
  @override
  _UserMapComponentState createState() => _UserMapComponentState();
}

class _UserMapComponentState extends State<UserMapComponent> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  double _currentZoom = 13.0;
  bool _isLoading = true;
  late UserHook _userHook;
  List<Polyline> _routeLines = [];
  LatLng? _driverPosition;
  String? _eta;
  bool _isDriverOffline = false;
  int _retryCount = 0;
  static const int MAX_RETRIES = 3;

  @override
  void initState() {
    super.initState();
    _initializeHook();
    _initializeLocation();
  }

  Future<void> _initializeHook() async {
    final prefs = await SharedPreferences.getInstance();
    _userHook = UserHook(prefs, 'YOUR_GEBETA_API_KEY');

    // Listen to driver updates
    _userHook.driverStream.listen((data) {
      setState(() {
        if (data['status'] == 'offline') {
          _isDriverOffline = true;
          _showOfflineAlert();
        } else {
          _isDriverOffline = false;
          if (data['location'] != null) {
            _driverPosition = LatLng(double.parse(data['location']['latitude']),
                double.parse(data['location']['longitude']));
          }
          if (data['route'] != null) {
            _updateRoute(data['route']);
          }
          if (data['eta'] != null) {
            _eta = _formatETA(data['eta']);
          }
        }
      });
    });
  }

  void _updateRoute(Map<String, dynamic> routeData) {
    List<LatLng> points = [];
    for (var coordinate in routeData['coordinates']) {
      points.add(LatLng(coordinate[1], coordinate[0]));
    }
    setState(() {
      _routeLines = [
        Polyline(
          points: points,
          strokeWidth: 4.0,
          color: Colors.blue,
        )
      ];
    });
  }

  void _showOfflineAlert() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Driver is currently offline'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ));
  }

  String _formatETA(double seconds) {
    int minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes mins';
    }
    int hours = (minutes / 60).floor();
    minutes = minutes % 60;
    return '$hours hr ${minutes}min';
  }

  Future<void> _initializeLocation() async {
    bool locationEnabled = await _checkLocationPermission();
    if (locationEnabled) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentPosition!, _currentZoom);
        _isLoading = false; // Stop loading after fetching location
      });
    } else {
      setState(() {
        _isLoading = false; // Stop loading if permission fails
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Location services are disabled. Please enable them.')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return false;
    }
    return true;
  }

  void _updatePosition(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
      _mapController.move(newPosition, _mapController.zoom);
    });
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(2.0, 18.0);
      _mapController.move(_currentPosition!, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(2.0, 18.0);
      _mapController.move(_currentPosition!, _currentZoom);
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _updatePosition(LatLng(position.latitude, position.longitude));
    } catch (e) {
      _showError('Could not get current location');
    }
  }

  void _retryConnection() async {
    if (_retryCount < MAX_RETRIES) {
      setState(() => _retryCount++);
      try {
        await _initializeLocation();
        setState(() => _retryCount = 0);
      } catch (e) {
        _showError('Connection failed');
      }
    } else {
      _showError('Max retries reached. Please try again later.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _retryConnection,
          textColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition,
              zoom: _currentZoom,
              onTap: (tapPosition, latLng) {
                _updatePosition(latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              // Show route
              PolylineLayer(polylines: _routeLines),
              // Show markers
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      builder: (ctx) => Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                  if (_driverPosition != null)
                    Marker(
                      point: _driverPosition!,
                      builder: (ctx) => Icon(
                        Icons.local_taxi,
                        color: _isDriverOffline ? Colors.grey : Colors.green,
                        size: 40.0,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // ETA Display
          if (_eta != null)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Text(
                  'ETA: $_eta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Add zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: _zoomIn,
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  onPressed: _zoomOut,
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Add current location button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: "currentLocation",
              onPressed: _goToCurrentLocation,
              child: Icon(Icons.my_location),
            ),
          ),

          // Add error retry widget
          if (_retryCount > 0)
            Positioned(
              top: 100,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Connection error. Retrying $_retryCount/$MAX_RETRIES',
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: _retryConnection,
                    ),
                  ],
                ),
              ),
            ),

          // Add offline indicator
          if (_isDriverOffline)
            Positioned(
              top: 150,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Driver is offline',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userHook.dispose();
    super.dispose();
  }
}
