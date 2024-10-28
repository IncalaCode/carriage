import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'DriverOTP.dart';

class RegisterDriver extends StatefulWidget {
  @override
  _RegisterDriverState createState() => _RegisterDriverState();
}

class _RegisterDriverState extends State<RegisterDriver> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String firstName = '';
  String lastName = '';
  String password = '';
  String confirmPassword = '';
  String carType = '';
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  XFile? drivingLicensePhoto;
  XFile? carPlatePhoto;
  XFile? idCardPhoto;
  XFile? driverPhoto;

  // Checkbox state management
  bool isDrivingLicenseTaken = false;
  bool isCarPlateTaken = false;
  bool isIdCardTaken = false;
  bool isDriverPhotoTaken = false;

  // Check and request camera permissions
  Future<bool> _requestCameraPermission() async {
    PermissionStatus cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      return true;
    } else if (cameraPermission.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Camera permission is required to take photos.'),
        duration: Duration(seconds: 2),
      ));
      return false;
    } else if (cameraPermission.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Camera Permission Required'),
          content: Text('Camera access is permanently denied. Please enable it from the app settings.'),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      );
      return false;
    }
    return false;
  }

  Future<void> _takePhoto(Function(XFile?) onPhotoTaken, String type) async {
    bool hasPermission = await _requestCameraPermission();
    if (hasPermission) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        onPhotoTaken(image);

        // Update the checkbox state and button text depending on the type
        setState(() {
          switch (type) {
            case 'DrivingLicense':
              isDrivingLicenseTaken = true;
              break;
            case 'CarPlate':
              isCarPlateTaken = true;
              break;
            case 'IdCard':
              isIdCardTaken = true;
              break;
            case 'DriverPhoto':
              isDriverPhotoTaken = true;
              break;
          }
        });
      }
    }
  }

  Widget _buildPhotoCheckbox(String label, Function(XFile?) onPhotoTaken, bool isTaken, String type) {
    return Row(
      children: [
        Checkbox(
          value: isTaken,
          activeColor: Colors.blue, // Change color to blue once checked
          onChanged: (bool? value) {
            if (!isTaken) {
              _takePhoto(onPhotoTaken, type);
            }
          },
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _takePhoto(onPhotoTaken, type);
            },
            child: Text(isTaken ? '$label Taken' : label),
            style: ElevatedButton.styleFrom(
              backgroundColor: isTaken ? Colors.green : Colors.black, // Set the background color
              foregroundColor: Colors.white,  // Set the text color
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Register Driver'),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // Enable autovalidation
          child: ListView(
            controller: _scrollController, // Added ScrollController
            children: [
              // First Name Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'First Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                onSaved: (value) {
                  firstName = value!;
                },
              ),
              SizedBox(height: 16),

              // Last Name Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
                onSaved: (value) {
                  lastName = value!;
                },
              ),
              SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      isPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  password = value!;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      isConfirmPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Car Type Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Car Type',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your car type';
                  }
                  return null;
                },
                onSaved: (value) {
                  carType = value!;
                },
              ),
              SizedBox(height: 16),

              // Driving License Photo Checkbox and Button
              _buildPhotoCheckbox('Take Driving License Photo', (photo) {
                setState(() {
                  drivingLicensePhoto = photo;
                });
              }, isDrivingLicenseTaken, 'DrivingLicense'),
              SizedBox(height: 16),

              // Car Plate Photo Checkbox and Button
              _buildPhotoCheckbox('Take Car Plate Photo', (photo) {
                setState(() {
                  carPlatePhoto = photo;
                });
              }, isCarPlateTaken, 'CarPlate'),
              SizedBox(height: 16),

              // ID Card Photo Checkbox and Button
              _buildPhotoCheckbox('Take ID Card Photo', (photo) {
                setState(() {
                  idCardPhoto = photo;
                });
              }, isIdCardTaken, 'IdCard'),
              SizedBox(height: 16),

              // User Photo Checkbox and Button
              _buildPhotoCheckbox('Take User Photo', (photo) {
                setState(() {
                  driverPhoto = photo;
                });
              }, isDriverPhotoTaken, 'DriverPhoto'),
              SizedBox(height: 16),

              ElevatedButton(
  onPressed: () {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DriverOTP()),
      );
    }
  },
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Next',
        style: TextStyle(color: Colors.white), // Text color
      ),
      SizedBox(width: 8),
      FaIcon(
        FontAwesomeIcons.arrowRight, // FontAwesome icon
        color: Colors.white,
      ),
    ],
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.black, // Button background color
    padding: EdgeInsets.symmetric(vertical: 16), // Padding for the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Rounded corners
      side: BorderSide(
        color: Colors.blue, // Blue border color
        width: 2, // Border width
      ),
    ),
    elevation: 4, // Elevation for shadow effect
  ),
),


            ],
          ),
        ),
      ),
    );
  }
}
