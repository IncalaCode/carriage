import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_map/user_hook.dart';

class OrderForm extends StatefulWidget {
  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController materialTypeController = TextEditingController();
  final TextEditingController carTypeController = TextEditingController();
  String? loadType;
  Timer? _debounce;

  final List<Map<String, String>> carTypes = [
    {'name': 'Sedan', 'image': 'assets/sedan.jpg'},
    {'name': 'SUV', 'image': 'assets/suv.jpg'},
    {'name': 'Truck', 'image': 'assets/truck.jpg'},
    {'name': 'Van', 'image': 'assets/van.jpg'},
  ];

  final Map<String, List<String>> _locationCache = {};
  String? selectedCarType;

  late UserHook _userHook;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeHook();
  }

  Future<void> _initializeHook() async {
    final prefs = await SharedPreferences.getInstance();
    _userHook = UserHook(prefs, 'YOUR_GEBETA_API_KEY');
  }

  @override
  void dispose() {
    fromController.dispose();
    destinationController.dispose();
    materialTypeController.dispose();
    carTypeController.dispose();
    _debounce?.cancel(); // Cancel debounce timer
    _userHook.dispose();
    super.dispose();
  }

  Future<List<String>> fetchLocationSuggestions(String query) async {
    if (query.isEmpty) return [];
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
                  address['state_district'] ?? '',
                  address['ISO3166-2-lvl4'] ?? '',
                  address['state'] ?? '',
                ].where((element) => element.isNotEmpty).join(", ");
              })
              .where((location) => location != null)
              .map((location) => location!)
              .toList();

          _locationCache[query] = locations;
          return locations;
        } else {
          _showErrorDialog("Failed to load location suggestions");
          return ["places not found under ethiopia"];
        }
      } catch (e) {
        _showErrorDialog("Error fetching location suggestions: $e");
        return ["places not found under ethiopia"];
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
    if (_isSubmitting) return;

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

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/client/handle-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "token": getToken(),
          'from': from,
          'destination': destination,
          'material_type': materialType,
          'car_type': carType,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog("Order submitted successfully!");
        // Start tracking after successful submission
        final data = json.decode(response.body);
        if (data['request_id'] != null) {
          _userHook.startTracking(data['request_id']);
        }
      } else if (response.statusCode == 303) {
        // Handle existing active request
        final data = json.decode(response.body);
        _showActiveRequestDialog(data);
      } else {
        _showError("Failed to submit order: ${response.body}");
      }
    } catch (e) {
      _showError("Network error: $e");
    } finally {
      setState(() => _isSubmitting = false);
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
                Navigator.of(context).pop();
                // Navigate to tracking screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        toolbarHeight: 80,
        centerTitle: true,
      ),
      body: Container(
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                  onPressed: _submitOrder, // Call the submit method
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Request',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: OrderForm()));
}

String getToken() {
  return "1u";
}
