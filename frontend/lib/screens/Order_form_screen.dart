import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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

  final List<Map<String, String>> carTypes = [
    {'name': 'Sedan', 'image': 'assets/sedan.jpg'},
    {'name': 'SUV', 'image': 'assets/suv.jpg'},
    {'name': 'Truck', 'image': 'assets/truck.jpg'},
    {'name': 'Van', 'image': 'assets/van.jpg'},
  ];

  String? selectedCarType;

  @override
  void dispose() {
    fromController.dispose();
    destinationController.dispose();
    materialTypeController.dispose();
    carTypeController.dispose();
    super.dispose();
  }

  Future<List<String>> getSuggestions(String query) async {
    // Replace this with a real location API.
    return ["Addis Ababa", "Hawassa", "Bahir Dar", "Mekelle", "Gondar"]
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _selectCarType() async {
    await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Car Type'),
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
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Image.asset(
                              car['image']!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text(car['name']!)),
                            SizedBox(width: 10),
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.transparent,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: isSelected ? Colors.blue : Colors.transparent,
                              ),
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
                  child: Text('Select'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Form'),
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
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Order Form',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TypeAheadFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: fromController,
                  decoration: InputDecoration(labelText: 'From (መነሻ)'),
                ),
                suggestionsCallback: getSuggestions,
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  fromController.text = suggestion;
                },
              ),
              TypeAheadFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: destinationController,
                  decoration: InputDecoration(labelText: 'Destination (መድረሻ)'),
                ),
                suggestionsCallback: getSuggestions,
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  destinationController.text = suggestion;
                },
              ),
              TextField(
                controller: materialTypeController,
                decoration: InputDecoration(labelText: 'Material Type (የሚጓጓዘው እቃ አይነት)'),
              ),
              GestureDetector(
                onTap: _selectCarType,
                child: AbsorbPointer(
                  child: TextField(
                    controller: carTypeController,
                    decoration: InputDecoration(labelText: 'Car Type'),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String from = fromController.text;
                  String destination = destinationController.text;
                  String materialType = materialTypeController.text;
                  String carType = carTypeController.text;
                  print(
                      'Order submitted: From - $from, Destination - $destination, Material Type - $materialType, Load Type - $loadType, Car Type - $carType');
                },
                child: Text('Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: OrderForm(),
  ));
}
