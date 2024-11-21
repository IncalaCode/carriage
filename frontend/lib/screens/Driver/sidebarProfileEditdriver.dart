import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'package:http/http.dart' as http; // Import the http package
import 'package:http_parser/http_parser.dart'; // For setting content type of image
import '../config.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditProfilePagedriver extends StatefulWidget {
  final File? profileImage;
  final String firstName ;
  final String lastName;
  final String phoneNumber;


  EditProfilePagedriver({
    Key? key,
    required this.profileImage,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePagedriver> {
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool isNewPhoneNumber = false;
  bool showOTPField = false;
  String? _otp; // Variable to store the OTP received from the backend
  String? _oldPhoneNumber; // Variable to store the old phone number

  // TextEditingControllers for the form fields
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _otpController = TextEditingController();
  TextEditingController _oldPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.firstName;
    _lastNameController.text = widget.lastName;
    _phoneController.text = widget.phoneNumber;
    _profileImage = widget.profileImage;

    _fetchOldPhoneNumber(); // Fetch the old phone number from shared preferences
  }

  // Method to fetch the old phone number from shared preferences
  Future<void> _fetchOldPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _oldPhoneNumber = prefs.getString('user_phone_number'); // Assuming 'phoneNumber' is the key used to store the phone number
      //_oldPhoneNumber = '+251953289595';
    });
    print('Fetched old phone number: $_oldPhoneNumber'); // Debug: Print the old phone number
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _onPhoneNumberChanged(String newPhoneNumber) {
    setState(() {
      isNewPhoneNumber = newPhoneNumber != widget.phoneNumber;
      showOTPField = isNewPhoneNumber;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _oldPhoneController.dispose();
    super.dispose();
  }

  // New method to send data to the backend
  Future<void> _updateProfile() async {

    // Prepare the data to send
    final String firstName = _firstNameController.text;
    final String lastName = _lastNameController.text;
    final File? profileImage = _profileImage;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('authToken') ?? '';

    print('Preparing to update profile with:');
    print('User ID: $userId');
    print('First Name: $firstName');
    print('Last Name: $lastName');
    if (profileImage != null) {
      print('Profile Image Path: ${profileImage.path}');
    } else {
      print('No profile image selected.');
    }

    var request = http.MultipartRequest('POST', Uri.parse(Config.baseUrl + '/driver/profile/update'));
    request.fields['token'] = userId; // Add user_id to the request
    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_picture', profileImage.path));
    }

    try {
      var response = await request.send();
      print('Response status code: ${response.statusCode}'); // Log the response status code

      // Check the response status code
      if (response.statusCode == 200) {
        // Handle success
        print('Profile updated successfully.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green, // Set background color to green
            ),
          );
        }
        Navigator.pop(context);
      } else if (response.statusCode == 303) {
        // Handle redirection
        print('Redirecting...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redirecting...'),
            ),
          );
        }
      } else {
        // Handle other error responses
        print('Failed to update profile. Status: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile. Status: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      // Handle exceptions
      print('An error occurred: $e'); // Log the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
          ),
        );
      }
    }
  }

  // Method to send OTP to the backend
  Future<void> _sendOTP() async {
    final String newPhoneNumber = _phoneController.text; // Get the new phone number from the input field

    print('Attempting to send OTP to new phone number: $newPhoneNumber'); // Debug: Print the new phone number
    print('Old phone number: $_oldPhoneNumber'); // Debug: Print the old phone number

    // Prepare the request to send OTP
    var request = http.post(
      Uri.parse(Config.baseUrl + '/driver/profile/send-otp'), // Replace with your actual endpoint
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldphone_number': _oldPhoneNumber, // Use the hardcoded old phone number
        'newphone_number': newPhoneNumber, // Use the new phone number from the input field
      }),
    );

    try {
      print('Sending request to backend...'); // Debug: Indicate request is being sent
      final response = await request;

      print('Response received. Status code: ${response.statusCode}'); // Debug: Print the response status code

      if (response.statusCode == 200) {
        // Handle success
        final responseData = jsonDecode(response.body); // Decode the response
        if (responseData is Map<String, dynamic> && responseData['status'] == 'success') {
          // Extract the OTP from the nested structure
          final String otp = responseData['otp']['data']['response']['message'].split(': ').last; // Extract OTP from the message

          print('OTP sent successfully to $newPhoneNumber: $otp'); // Print the OTP for testing
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OTP sent to $newPhoneNumber')),
            );
          }
        } else {
          print('Unexpected response format: $responseData'); // Debug: Print unexpected response
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unexpected response format')),
            );
          }
        }
      } else {
        // Handle error
        print('Failed to send OTP. Status: ${response.statusCode}'); // Debug: Print failure status
        print('Response body: ${response.body}'); // Debug: Print the response body for more details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP. Status: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('An error occurred while sending OTP: $e'); // Debug: Print the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while sending OTP: $e')),
        );
      }
    }
  }

  // Method to confirm OTP
  Future<void> _confirmOTP() async {
    final String newPhoneNumber = _phoneController.text; // Get the new phone number from the input field
    final String otp = _otpController.text; // Get the OTP entered by the user

    // Prepare the request to confirm OTP
    var request = http.post(
      Uri.parse(Config.baseUrl + '/driver/profile/verifyotp'), // Replace with your actual endpoint
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'newphone_number': newPhoneNumber, // Send the new phone number
        'otp': otp, // Send the OTP
      }),
    );

    try {
      final response = await request;

      if (response.statusCode == 200) {
        // Handle success
        print('OTP confirmed successfully.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP confirmed! Profile updated successfully.'),
              backgroundColor: Colors.green, // Set background color to green
            ),
          );
        }
        // Proceed with further actions, e.g., updating the profile
      } else {
        // Handle error
        print('Failed to confirm OTP. Status: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to confirm OTP. Status: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      print('An error occurred while confirming OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while confirming OTP: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _profileImage == null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        child: FaIcon(
                          FontAwesomeIcons.user,
                          size: 50,
                          color: Colors.grey.shade700,
                        ),
                      )
                    : CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_profileImage!),
                      ),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  hintText: widget.firstName,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  hintText: widget.lastName,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: _oldPhoneNumber ?? widget.phoneNumber,
                  suffixIcon: isNewPhoneNumber
                      ? SizedBox(
                          width: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color.fromARGB(255, 80, 80, 80), Color.fromARGB(255, 192, 163, 197)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextButton(
                              onPressed: () {
                                _sendOTP(); // Call the method to send OTP
                              },
                              child: Text('Send OTP', style: TextStyle(color: Colors.white)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: _onPhoneNumberChanged,
              ),
              SizedBox(height: 16),

              if (showOTPField)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP',
                          hintText: 'Enter OTP',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color.fromARGB(255, 80, 80, 80), Color.fromARGB(255, 192, 163, 197)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextButton(
                          onPressed: () {
                            _confirmOTP(); // Call the method to confirm OTP
                          },
                          child: Text('Confirm', style: TextStyle(color: Colors.white)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF000000), Color(0xFF9A839E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _updateProfile(); // Call the new method
                    }
                  },
                  child: Text(
                    'Update',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shadowColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
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
