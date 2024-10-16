import 'package:flutter/material.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'DriverOTP.dart';

class RegisterDriver extends StatefulWidget {
  @override
  _RegisterDriverState createState() => _RegisterDriverState();
}

class _RegisterDriverState extends State<RegisterDriver> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _takePhoto(Function(XFile?) onPhotoTaken) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera); 
    if (image != null) {
      onPhotoTaken(image);
    }
  }

Widget _buildPhotoButton(String label, Function(XFile?) onPhotoTaken) {
  return ElevatedButton(
    onPressed: () => _takePhoto(onPhotoTaken),
    child: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black, // Set the background color
      foregroundColor: Colors.white,  // Set the text color
    ),
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
          child: ListView(
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
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
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

              // Driving License Photo Button
              _buildPhotoButton('Take Driving License Photo', (photo) {
                setState(() {
                  drivingLicensePhoto = photo;
                });
              }),
              SizedBox(height: 16),

              // Car Plate Photo Button
              _buildPhotoButton('Take Car Plate Photo', (photo) {
                setState(() {
                  carPlatePhoto = photo;
                });
              }),
              SizedBox(height: 16),

              // ID Card Photo Button
              _buildPhotoButton('Take ID Card Photo', (photo) {
                setState(() {
                  idCardPhoto = photo;
                });
              }),
              SizedBox(height: 16),

              // User Photo Button
              _buildPhotoButton('Take User Photo', (photo) {
                setState(() {
                  driverPhoto = photo;
                });
              }),
              SizedBox(height: 16),

              ElevatedButton.icon(
                icon: Icon(FontAwesomeIcons.arrowRight, color: Colors.blue),
                label: Text('Next', style: TextStyle(color: Colors.blue)),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Ensure all photos are taken
                    if (drivingLicensePhoto == null || carPlatePhoto == null || idCardPhoto == null || driverPhoto == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Please take all required photos'),
                        backgroundColor: Colors.red,
                      ));
                    } else {
                      // Navigate to OTP Screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DriverOTP()),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
