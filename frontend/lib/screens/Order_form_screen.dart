import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
              title: Text('Select Car Type', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected ? Colors.grey.shade300 : Colors.white,
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
                            )),
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: isSelected ? Colors.black : Colors.grey.shade300,
                              child: isSelected
                                  ? Icon(FontAwesomeIcons.check, size: 14, color: Colors.white)
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
                  child: Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    labelText: 'From (መነሻ)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                suggestionsCallback: getSuggestions,
                itemBuilder: (context, suggestion) {
                  return ListTile(title: Text(suggestion));
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                suggestionsCallback: getSuggestions,
                itemBuilder: (context, suggestion) {
                  return ListTile(title: Text(suggestion));
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 75, 75, 75)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    String from = fromController.text;
                    String destination = destinationController.text;
                    String materialType = materialTypeController.text;
                    String carType = carTypeController.text;
                    print('Order submitted: From - $from, Destination - $destination, Material Type - $materialType, Load Type - $loadType, Car Type - $carType');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Request',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
