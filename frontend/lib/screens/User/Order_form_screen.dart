import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_map/user_hook.dart';
import 'package:geolocator/geolocator.dart';
import '../config.dart';
import './main_app_screen.dart';

class OrderForm extends StatefulWidget {
  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController materialTypeController = TextEditingController();
  final TextEditingController carTypeController = TextEditingController();
  Timer? _debounce;

  final List<Map<String, String>> carTypes = [
    {'name': 'Sedan', 'image': 'assets/sedan.jpg'},
    {'name': 'SUV', 'image': 'assets/suv.jpg'},
    {'name': 'Truck', 'image': 'assets/truck.jpg'},
    {'name': 'Van', 'image': 'assets/van.jpg'},
  ];

  final Map<String, List<String>> _locationCache = {};
  String? selectedCarType;

  UserHook? _userHook;
  List<Map<String, dynamic>> drivers = [];
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _showForm = false; // Start with the form shown
  String? _errorMessage; // Variable to hold the error message
  bool _hasActiveOrder = false; // New variable to track active order status
  bool is_accept = false;

  @override
  void initState() {
    super.initState();
    _initializeHook();
  }

  Future<void> _initializeHook() async {
    final prefs = await SharedPreferences.getInstance();
    _userHook = UserHook(prefs);
    _userHook!.driverStream.listen((data) {
      if (data['statusCode'] == 200) {
        // Update drivers list when new data is received
        setState(() {
          drivers = List<Map<String, dynamic>>.from(data['drivers'] ?? []);
          _hasActiveOrder = drivers.isNotEmpty; // Update active order status
          _isLoading = !drivers.isNotEmpty;
        });
      } else if (data['statusCode'] == 303) {
        Navigator.pop(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          print(data['drivers']['image']);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => RideInfoCard(
              name: data['drivers']['name'] ?? "",
              phone: data['drivers']['phone'] ?? "",
              photoUrl: data['drivers']['image'] ?? "",
              distance: "calculating..",
              time: "calculating..",
            ),
          );
        });
      } else if (data['statusCode'] == 401) {
        _showError(data['error'] ?? "An unknown error occurred.");
        setState(() {
          _errorMessage = data['error'] ?? "An unknown error occurred.";
          _isLoading = false;
          _hasActiveOrder = false;
          _userHook!.stoppolling();
          // Store the error message
        });
      }
    });
    // Start polling for driver requests
    _userHook!.startPolling();
  }

  @override
  void dispose() {
    fromController.dispose();
    destinationController.dispose();
    materialTypeController.dispose();
    carTypeController.dispose();
    _debounce?.cancel(); // Cancel debounce timer
    _userHook?.dispose();
    super.dispose();
  }

  Future<List<String>> fetchLocationSuggestions(String query) async {
    if (query.isEmpty)
      return ["Loading..."]; // Return "Loading..." if query is empty

    if (_locationCache.containsKey(query)) return _locationCache[query]!;

    return await Future.delayed(Duration(milliseconds: 300), () async {
      final url =
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=ET';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final locations = data
              .map<String?>((item) {
                final address = item['address'];
                return [
                  address['residential'] ?? '',
                  address['road'] ?? '', // Use 'road' for street names
                  address['suburb'] ?? '',
                  address['ISO3166-2-lvl4'] ?? '',
                  address['state'] ?? '',
                ].where((element) => element.isNotEmpty).join(", ");
              })
              .where((location) =>
                  location != null &&
                  location.isNotEmpty) // Filter out empty locations
              .map((location) => location!)
              .toList();

          _locationCache[query] = locations.isNotEmpty
              ? locations
              : ["Loading..."]; // Return "Loading..." if no locations found
          return _locationCache[query]!;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to load location suggestions"),
              backgroundColor: Colors.red,
            ),
          ); // Using Flutter's built-in error display
          return ["Loading..."]; // Return "Loading..." on error
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching location suggestions: no internet  "),
            backgroundColor: Colors.red,
          ),
        ); // Using Flutter's built-in error display
        return ["Loading..."]; // Return "Loading..." on exception
      }
    });
  }

  void _selectCarType() async {
    await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Car Type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Container(
                height: 300,
                width: double.maxFinite,
                child: ListView.separated(
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemCount: carTypes.length,
                  itemBuilder: (context, index) {
                    final car = carTypes[index];
                    final isSelected = selectedCarType == car['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCarType = car['name'];
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              isSelected ? Colors.grey.shade300 : Colors.white,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.grey.shade600,
                                blurRadius: 5,
                              )
                          ],
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              car['image']!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                car['name']!,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              child: isSelected
                                  ? Icon(FontAwesomeIcons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(selectedCarType);
                  },
                  child: Text('Select',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ).then((selectedCar) {
      if (selectedCar != null) {
        setState(() {
          carTypeController.text = selectedCar;
        });
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting || _isLoading) return;

    String from = fromController.text;
    String destination = destinationController.text;
    String materialType = materialTypeController.text;
    String carType = carTypeController.text;

    if (from.isEmpty ||
        destination.isEmpty ||
        materialType.isEmpty ||
        carType.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isLoading = true;
    });

    try {
      final position = await getCurrentPosition(); // Get current position
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/client/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          _hasActiveOrder ? "update" : "create": null,
          "token": getToken(),
          'from': from,
          'destination': destination,
          'material_type': materialType,
          'car_type': carType,
          'latitude': position.latitude.toString(), // Add latitude
          'longitude': position.longitude.toString(), // Add longitude
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog("Order submitted successfully!");
        // Start tracking after successful submission
        final data = json.decode(response.body);
        if (data['request_id'] != null) {
          // do somrthing here
        }
      } else if (response.statusCode == 303 || response.statusCode == 400) {
        // Handle existing active request
        final data = json.decode(response.body);
        _showActiveRequestDialog(data);
      } else {
        final data = json.decode(response.body);
        _showError("Failed to submit order: ${data}");
      }
    } catch (e) {
      _showError("Network error");
    } finally {
      setState(() {
        _isSubmitting = false;
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showForm = false;
                  _isLoading = true;
                  _userHook!.startPolling(); // Redirect to _buildDefaultView
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showActiveRequestDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Active Request Exists'),
          content: Text(
              'You have an active request from: ${data['current_request']['from']}\n'
              'To: ${data['current_request']['destination']}'),
          actions: [
            TextButton(
              child: Text('View Status'),
              onPressed: () {
                // Navigate to tracking screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void accept(String driverId) async {
    setState(() {
      is_accept = true;
    });
    print("Accept button pressed for driver ID: ${driverId}");
    final String token = getToken(); // Get the token
    final String url = '${Config.baseUrl}/client/handle-request'; // Backend URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driver_id': driverId,
          'token': token,
// Indicate that this is an update request
        }),
      );

      if (response.statusCode == 200) {
        // Handle successful response
        final data = json.decode(response.body);
        // Assuming the response contains driver's details
        String driverName = data['driver']['name'] ?? "";
        String driverPhone = data['driver']['phone'] ?? "";
        String driverImage = data['driver']['image'] ?? "";

        Navigator.pop(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => RideInfoCard(
              name: driverName,
              phone: driverPhone,
              photoUrl: driverImage,
              distance: "calculating..",
              time: "calculating..",
            ),
          );
        });

        // Navigate to tracking screen with driver's details
      } else {
        // Handle error response
        final data = json.decode(response.body);
        _showError(data['error'] ?? 'An error occurred'); // Show error message
      }
    } catch (e) {
      _showError("Network error"); // Handle network errors
    } finally {
      setState(() {
        is_accept = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000000), Color(0xFF9A839E)],
            ),
          ),
        ),
        toolbarHeight: 80,
        centerTitle: true,
        leading: IconButton(
          color: Colors.white,
          icon: Icon(FontAwesomeIcons.arrowLeft), // Back button icon
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to the previous screen
          },
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon:
                Icon(_showForm ? FontAwesomeIcons.list : FontAwesomeIcons.edit),
            onPressed: () {
              setState(() {
                _showForm = !_showForm; // Toggle the view
              });
            },
          ),
        ],
      ),
      body: _showForm
          ? _buildOrderForm()
          : _buildDefaultView(), // Conditional rendering
    );
  }

  Widget _buildDefaultView() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator()); // Show loading indicator
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(20),
            title: Text(
              driver['name'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${driver['name']}'),
                Text('Price: ${driver['price']} birr'),
                Text('Car Type: ${driver['car_type'] ?? 'UNKNOWN'}'),
                Text(
                    '${calculateDistance(driver['latitude'], driver['longitude'])}' ??
                        "unknown"),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                final driverId = driver['driver_id']?.toString() ??
                    ''; // Safely convert to string or use an empty string
                accept(driverId); // Pass the driverId to the accept function
              },
              child: !is_accept
                  ? Text('Accept')
                  : CircularProgressIndicator(strokeWidth: 2),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderForm() {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade200],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Order Form',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            SizedBox(height: 20),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: fromController,
                decoration: InputDecoration(
                  labelText: 'From (ከ)',
                  hintText: 'አዲስ አበባ - ቂርቆስ - ወረዳ 04 - ጎተራ',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await fetchLocationSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                fromController.text = suggestion;
              },
            ),
            SizedBox(height: 10),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination (መድረሻ)',
                  hintText: 'አዲስ አበባ - ቂርቆስ - ወረዳ 04 - ጎተራ',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await fetchLocationSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                destinationController.text = suggestion;
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: materialTypeController,
              decoration: InputDecoration(
                labelText: 'Material Type (የሚጓጓዘው እቃ አይነት)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: _selectCarType,
              child: AbsorbPointer(
                child: TextField(
                  controller: carTypeController,
                  decoration: InputDecoration(
                    labelText: 'Car Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF9A839E)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        _hasActiveOrder
                            ? 'Update Request'
                            : 'Request', // Change button text based on active order
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future calculateDistance(double endLatitude, double endLongitude) async {
    final position = await getCurrentPosition();

    double startLatitude = position.latitude;
    double startLongitude = position.longitude;

    double value = Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
    return "Distance: ${value / 1000} km";
  }
}

void main() {
  runApp(MaterialApp(home: OrderForm()));
}

String getToken() {
  return "1u";
}
