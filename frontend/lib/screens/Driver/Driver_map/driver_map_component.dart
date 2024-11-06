import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import './driver_hock.dart';

class DriverMapComponent extends StatefulWidget {
  @override
  _DriverMapComponentState createState() => _DriverMapComponentState();
}

class _DriverMapComponentState extends State<DriverMapComponent> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  double _currentZoom = 9.0;
  bool _isLoading = true;
  late DriverHook _driverHook;
  List<Polyline> _routeLines = [];
  List<Marker> _requestMarkers = [];
  bool _isOnline = true;
  int _retryCount = 0;
  static const int MAX_RETRIES = 3;
  // Example placeholder values. Replace with actual initialization.
  late final dynamic _localStorage; // Adjust type as needed
  late final String gebetaApiKey = "YOUR_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _initializeHook();
    _initializeLocation();
  }

  Future<void> _initializeHook() async {
    _driverHook = DriverHook(this._localStorage, this.gebetaApiKey);
    _driverHook.ordersStream.listen((data) {
      setState(() {
        if (data['orders'] != null) {
          _updateRequestMarkers(data['orders']);
        }
        if (data['route'] != null) {
          _updateRoute(data['route']);
        }
      });
    });
    _driverHook.startPolling();
  }

  void _updateRequestMarkers(List<dynamic> orders) {
    _requestMarkers = orders.map((order) {
      return Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(
            double.parse(order['latitude']), double.parse(order['longitude'])),
        builder: (ctx) => GestureDetector(
          onTap: () => _showOrderDetails(order),
          child: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40.0,
          ),
        ),
      );
    }).toList();
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('From: ${order['from']}'),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('To: ${order['destination']}'),
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text('Material: ${order['material_type']}'),
            ),
            ElevatedButton(
              onPressed: () => _acceptOrder(order['id']),
              child: Text('Accept Order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      // Implementation of order acceptance
      Navigator.pop(context); // Close bottom sheet
    } catch (e) {
      _showError('Failed to accept order');
    }
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

  void _updateRoute(List<dynamic> route) {
    // Clear existing route lines
    _routeLines.clear();

    // Create new polylines based on the route data
    _routeLines = [
      Polyline(
        points: route
            .map((point) => LatLng(point['latitude'], point['longitude']))
            .toList(),
        strokeWidth: 4.0,
        color: Colors.blue,
      ),
    ];
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
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              PolylineLayer(polylines: _routeLines),
              MarkerLayer(markers: [
                if (_currentPosition != null)
                  Marker(
                    point: _currentPosition!,
                    builder: (ctx) => Icon(
                      Icons.local_taxi,
                      color: _isOnline ? Colors.green : Colors.grey,
                      size: 40.0,
                    ),
                  ),
                ..._requestMarkers,
              ]),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: "currentLocation",
              onPressed: _goToCurrentLocation,
              child: Icon(FontAwesomeIcons.locationArrow), // Fixed typo here
            ),
          ),
          Positioned(
            left: 16,
            top: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: Switch(
                value: _isOnline,
                onChanged: _toggleOnlineStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleOnlineStatus(bool value) {
    setState(() {
      _isOnline = value;
      if (_isOnline) {
        _driverHook.startPolling();
      } else {
        _driverHook.stopPolling();
      }
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
  void dispose() {
    _driverHook.dispose();
    super.dispose();
  }
}
