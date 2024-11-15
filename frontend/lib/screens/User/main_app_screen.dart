import 'package:My_truck/screens/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sidebarProfile.dart';
import 'sidebarWallet.dart';
import './sidebarMyOrder.dart';
import 'sidebarSettings.dart';
import 'Order_form_screen.dart';
import 'user_map/user_map_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'dart:async';

late Function(bool) function;
bool is_tracking = false;

class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  Stream<bool>? stream;
  bool isDrawerOpen = false;
  File? _profileImage;
  double _walletBalance = 1500.0;
  bool _isLoading = false;
  //   double _walletBalance = 0.0;
  // bool _isLoading = true;
  String? _paymentUrl;
  String? _authToken;

  bool _isRideInfoVisible =
      false; // New state to control RideInfoCard visibility

  RideInfoCard? rideInfoCard;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    checkData(); // make it to check frist
    function = change;
  }

  void change(bool value) {
    print("ehheheesmnssss eheehehheh ${is_tracking}");
    setState(() {
      is_tracking = value;
      if (!is_tracking) {
        _checkAuthentication();
        _isLoading = true;
      }
    });
  }

  Future<void> checkData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('name')) {
      // Create the RideInfoCard with a key
      rideInfoCard = RideInfoCard(
        name: prefs.getString('name') ?? '',
        phone: prefs.getString('phone') ?? '',
        photoUrl: prefs.getString('photoUrl') ?? '',
        distance: prefs.getString('distance') ?? '0',
        time: prefs.getString('time') ?? '',
        change: function,
      );

      // change();

      // Show the RideInfoCard if data exists
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => rideInfoCard!,
        );
      });

      // Use the key to update the ride information dynamically
      // rideInfoCardKey.currentState?._updateRideInfo("24km", "11min");
    }
  }

  void _toggleRideInfoCard() async {
    final prefs = await SharedPreferences.getInstance();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => rideInfoCard = RideInfoCard(
              name: prefs.getString('name') ?? '',
              phone: prefs.getString('phone') ?? '',
              photoUrl: prefs.getString('photoUrl') ?? '',
              distance: prefs.getString('distance') ?? '0',
              time: prefs.getString('time') ?? '',
              change: function,
            ));
  }

  Future<void> _initializeScreen() async {
    try {
      // await _checkAuthentication();
      // if (_authToken != null) {
      //   await _fetchWalletBalance();
      // }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAuthentication() async {
    print('🔐 Starting authentication check');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('🔑 Raw token from storage: $token');

    if (token == null) {
      print('❌ No token found - Redirecting to login');
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (context) => LoginScreen()),
      // );
    } else {
      print('✅ Token found - Proceeding with authentication');
      setState(() {
        _authToken = token;
      });
      print('🔑 Formatted token: $_authToken');
    }
  }

  Future<void> _fetchWalletBalance() async {
    if (_authToken == null) return;

    try {
      final url = Uri.parse('${Config.baseUrl}/wallet/balance');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': _authToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _walletBalance = double.parse(data['balance'].toString());
            _isLoading = false;
          });
        }
      } else {
        throw Exception(
            'Failed to load wallet balance: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (_authToken == null) return;

    try {
      final url = Uri.parse('${Config.baseUrl}/user/request/initiate-payment');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authToken!,
        },
        body: json.encode({
          'token': _authToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _paymentUrl = data['payment_url'];
        });
        _showPaymentWebView();
      } else {
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to initiate payment. Please try again.')),
      );
    }
  }

  void _showPaymentWebView() async {
    if (_paymentUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Payment'),
            backgroundColor: Colors.black,
          ),
          body: WebView(
            initialUrl: _paymentUrl,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              print(request);
              if (request.url.contains('success')) {
                final uri = Uri.parse(request.url);
                final txref = uri.queryParameters['tx_ref'];
                final uid = uri.queryParameters['uid'];

                if (txref != null && uid != null) {
                  _confirmPayment(txref, uid);
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPayment(String txref, String uid) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/user/request/confirm-payment'),
        headers: {
          'Authorization': _authToken!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tx_ref': txref,
          'token': _authToken,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close WebView
        await _fetchWalletBalance(); // Refresh wallet balance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment successful! Wallet has been updated.')),
        );
      } else {
        throw Exception('Payment confirmation failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Payment confirmation failed. Please contact support.')),
      );
    }
  }

  void _showOrderForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderForm()),
    );
  }

  Widget _buildOrderButton() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 10),
            Text('Loading wallet...',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_walletBalance >= 1500) {
      return FloatingActionButton.extended(
        onPressed: is_tracking ? _toggleRideInfoCard : _showOrderForm,
        backgroundColor: Colors.transparent,
        icon: Icon(FontAwesomeIcons.bell, color: Colors.white),
        label: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000000), Color(0xFF9A839E)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            is_tracking ? "See your order" : "Order Now",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: _initiatePayment,
        backgroundColor: Colors.transparent,
        icon: Icon(FontAwesomeIcons.lock, color: Colors.white),
        label: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900, Colors.red.shade700],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Pay 1500 ETB to Access Orders',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000000), Color(0xFF9A839E)],
            ),
          ),
        ),
        toolbarHeight: 80,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Image.asset('assets/Nave.png', height: 100),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 0, right: 16.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(FontAwesomeIcons.bars, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isDrawerOpen = true;
                  });
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF9A839E)],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: _profileImage == null
                          ? Icon(FontAwesomeIcons.user,
                              size: 40, color: Colors.grey)
                          : ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'User!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(FontAwesomeIcons.user, 'Profile', context,
                      () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', context,
                      () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WalletPage()),
                    );
                  }),
                  _buildDrawerItem(
                      FontAwesomeIcons.shoppingCart, 'My Orders', context, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyOrdersPage()),
                    );
                  }),
                  _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', context,
                      () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  }),
                ],
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          UserMapComponent(),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildOrderButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      IconData icon, String title, BuildContext context, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      tileColor: Colors.grey[200],
      onTap: () => onTap(),
    );
  }
}

// Add payment verification function
Future<bool> _verifyPayment() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    print('Verifying payment with token: $token'); // Debug print

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/driver/payment/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print(
        'Payment verification response status: ${response.statusCode}'); // Debug print
    print('Payment verification response: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['payment_verified'] == true;
    }
    return false;
  } catch (e) {
    print('Error verifying payment: $e'); // Debug print
    return false;
  }
}

// Update the PaymentWebView to handle verification
class PaymentWebView extends StatelessWidget {
  final String paymentUrl;
  final String token;

  const PaymentWebView({
    required this.paymentUrl,
    required this.token,
  });

  Future<void> _handlePaymentSuccess(BuildContext context) async {
    Navigator.pop(context); // Close payment webview

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying payment...')
            ],
          ),
        );
      },
    );

    // Wait a bit for backend to process payment
    await Future.delayed(Duration(seconds: 2));

    // Verify payment
    final bool isVerified = await _verifyPayment();

    Navigator.pop(context); // Close loading dialog

    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment verified successfully!')));
      // Refresh wallet balance and proceed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderForm()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Payment verification failed. Please contact support if money was deducted.'),
        duration: Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebView(
        initialUrl: paymentUrl,
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: (NavigationRequest request) {
          print('Navigation to: ${request.url}'); // Debug print
          if (request.url.contains('success')) {
            _handlePaymentSuccess(context);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}

// Import Stream
// Import Stream
class RideInfoCard extends StatefulWidget {
  final String name;
  final String phone;
  final String photoUrl;
  final String distance;
  final String time;
  final Function(bool) change;

  RideInfoCard({
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.distance,
    required this.time,
    required this.change,
  });

  @override
  _RideInfoCardState createState() => _RideInfoCardState();
}

class _RideInfoCardState extends State<RideInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  late String _currentDistance;
  late String _currentTime;

  // StreamController to update distance and time

  bool _isOpen = true; // New variable to control visibility

  @override
  void initState() {
    super.initState();

    _currentDistance = widget.distance;
    _currentTime = widget.time;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    saveData();
  }

  @override
  void dispose() {
// Close stream controller
    _controller.dispose();
    super.dispose();
  }

  // Save data to SharedPreferences
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', widget.name);
    await prefs.setString('phone', widget.phone);
    await prefs.setString('photoUrl', widget.photoUrl);
    await prefs.setString('distance', _currentDistance);
    await prefs.setString('time', _currentTime);

    widget.change(true);
  }

  // Function to handle completion
  void _completeRide() async {
    final token = await getToken();
    final prefs = await SharedPreferences
        .getInstance(); // Retrieve token dynamically if async
    final response =
        await http.post(Uri.parse('${Config.baseUrl}/client/handle-request'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'token': token, "completed": true}));

    final dynamic data = json.decode(response.body);

    _toggleVisibility();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride set completed successfully!')),
      );
      prefs.remove("name");
      widget.change(false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride set not  completed !'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Logic for completing the ride
  }

  // Function to show warning before completing
  void _showCompletionWarning() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Complete Ride'),
          content: Text('Are you sure your order is completed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _completeRide(); // Call the complete function
              },
              child: Text('Yes, confirm'),
            ),
          ],
        );
      },
    );
  }

  void _toggleVisibility() {
    setState(() {
      _isOpen = !_isOpen; // Toggle the visibility
    });
  }

  @override
  Widget build(BuildContext context) {
    print("shsssssssssssss" + widget.photoUrl);

    // final res = http.get(
    //   Uri.parse(Config.imagebaseUrl + widget.photoUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    // );

    // print(res);

    return SlideTransition(
      position: _offsetAnimation,
      child: _isOpen // Check the visibility state
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        //  backgroundImage: NetworkImage(''),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "+" + widget.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showCompletionWarning,
                    child: Text('Complete Ride'),
                  ),
                ],
              ),
            )
          : SizedBox.shrink(), // Return an empty widget when closed
    );
  }
}
