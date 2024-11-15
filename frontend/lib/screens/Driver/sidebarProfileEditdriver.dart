import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditProfilePagedriver extends StatefulWidget {
  final File? profileImage;
  final String firstName;
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

  // TextEditingControllers for the form fields
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.firstName;
    _lastNameController.text = widget.lastName;
    _phoneController.text = widget.phoneNumber;
    _profileImage = widget.profileImage;
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
    super.dispose();
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
                  hintText: widget.phoneNumber,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('OTP Sent!')),
                                );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('OTP Confirmed!')),
                            );
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Profile Updated!')),
                      );
                      Navigator.pop(context);
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
