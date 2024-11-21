import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'sidebarProfileEditdriver.dart';
import '../login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePagedriver extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePagedriver> {
  File? _profileImage;
  bool isApproved = true;
  String referralCode = "";
  List<String> referrals = [];
  final int referralReward = 1000;
  String? _authToken;
  String _displayName = '';
  String _phoneNumber = '';
  int referralCount = 0;
  String _status ='';
  String _referralCode = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      setState(() {
        _authToken = token;
      });
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    if (_authToken == null) return;

    final driverId = _authToken; // Replace with actual driver ID if different from token
    final url = Uri.parse('${Config.baseUrl}/driver/profile');

    print('🔑 Driver ID: $driverId');
    print('🔗 Profile endpoint URL: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': driverId,
      }),
    );

    print('💳 Profile Response Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _displayName = data['first_name'] ?? _displayName;
        _phoneNumber = data['phone_number'] ?? _phoneNumber;
        
        isApproved = data['status'] == 'Verified'; // Set to true if status is 'Verified', else false
        
        referralCode = data['referral_code'] ?? referralCode;
        
        referrals = List<String>.from(data['my_referrals'] ?? []);
        referralCount = referrals.length;

        _profileImageUrl = data['image'];
      });
    } else {
      print('Failed to load profile data: ${response.statusCode}');
    }
  }

    void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete token and navigate to login screen
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear all stored shared preferences
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF000000),
                      Color(0xFF9A839E)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Referral code copied to clipboard")),
    );
  }

  String get displayReferralCode {
    return referralCode.length > 4 ? referralCode.substring(referralCode.length - 4) : referralCode;
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
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.userEdit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePagedriver(
                    profileImage: _profileImage,
                    firstName: 'Jabez',
                    lastName: 'Hap',
                    phoneNumber: '+251 963 488 972',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                child: _profileImage == null && _profileImageUrl == null
                    ? Icon(
                        FontAwesomeIcons.user,
                        size: 50,
                        color: const Color.fromARGB(255, 52, 52, 52),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _displayName,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.phone, size: 20, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        _phoneNumber,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Status: "),
                Icon(
                  isApproved ? FontAwesomeIcons.check : FontAwesomeIcons.times,
                  color: isApproved ? Colors.green : Colors.red,
                  size: 20,
                ),
                Text(
                  isApproved ? " Approved" : " Not Approved",
                  style: TextStyle(
                    color: isApproved ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Referral Code: "),
                Text(
                  displayReferralCode,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(FontAwesomeIcons.copy),
                  onPressed: () {
                    _copyReferralCode();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "My Referrals",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Referrals: ${referrals.length}",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Total Gain: ${referrals.length * referralReward} Birr",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 15),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.builder(
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(FontAwesomeIcons.user, color: Colors.grey),
                      title: Text(referrals[index]),
                    );
                  },
                ),
              ),
            ),
            Spacer(),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000000),
                    Color(0xFF9A839E),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ElevatedButton.icon(
                icon: FaIcon(FontAwesomeIcons.signOutAlt, color: Colors.white),
                label: Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: _showLogoutConfirmation,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

