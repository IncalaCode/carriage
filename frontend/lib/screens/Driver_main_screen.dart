import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'config.dart';
import 'login_screen.dart';
import 'OrderRequestsPage.dart';
import 'sidebarProfile.dart';
import 'sidebarWallet.dart';
import 'sidebarMyOrder.dart';
import 'sidebarSettings.dart';
import './Driver_map/driver_map_component.dart';
import './Driver_map/driver_hock.dart';

class DriverMainScreen extends StatefulWidget {
  @override
  _DriverMainScreenState createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  bool isDrawerOpen = false;
  bool loading = true; // Loading state
  File? _profileImage;
  String? _authToken;
  double _walletBalance = 0.0;
  bool _isLoading = true;
  String? _paymentUrl;

  @override
  void initState() {
    super.initState();
    print('🚀 Initializing Driver Main Screen');
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      print('🔄 Starting screen initialization');
      await _checkAuthentication();
      if (_authToken != null) {
        print('🔑 Token verified, fetching wallet balance');
        await _fetchWalletBalance();
      }
    } catch (e) {
      print('❌ Initialization Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAuthentication() async {
    print('🔐 Starting authentication check');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('🔑 Retrieved token: $token');

    if (token == null) {
      print('❌ No token found - Redirecting to login');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      print('✅ Token found - Proceeding with authentication');
      setState(() {
        _authToken = token;
      });
    }
  }

  Future<void> _fetchWalletBalance() async {
    if (_authToken == null) {
      print('❌ No auth token available for wallet check');
      return;
    }

    try {
      print('💳 Fetching wallet balance with token: ${_authToken!.substring(0, 10)}...');
      final url = Uri.parse('${Config.baseUrl}/wallet/balance');
      print('🔗 Wallet endpoint URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      print('💰 Wallet Response Status: ${response.statusCode}');
      print('💰 Wallet Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💰 Parsed wallet data: $data');
        if (mounted) {
          setState(() {
            _walletBalance = double.parse(data['balance'].toString());
            _isLoading = false;
          });
        }
        print('💰 Wallet balance updated: $_walletBalance ETB');
      } else {
        print('❌ Failed to load wallet: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        throw Exception('Failed to load wallet balance: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Wallet Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiatePayment() async {
    try {
      print('💳 Initiating payment process...');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/initiate-payment'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      print('💳 Payment Initiation Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔗 Payment URL Received: ${data['payment_url']}');
        setState(() {
          _paymentUrl = data['payment_url'];
        });
        _showPaymentWebView();
      } else {
        throw Exception('Failed to initiate payment');
      }
    } catch (e) {
      print('❌ Payment Initiation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate payment. Please try again.')),
      );
    }
  }

  void _showPaymentWebView() {
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
              print('🔄 Navigation to: ${request.url}');
              
              // Check for success URL and extract txref and uid
              if (request.url.contains('success')) {
                final uri = Uri.parse(request.url);
                final txref = uri.queryParameters['tx_ref'];
                final uid = uri.queryParameters['uid'];
                
                if (txref != null && uid != null) {
                  print('✅ Payment Success - txref: $txref, uid: $uid');
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
      print('✅ Confirming payment with backend...');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/confirm-payment'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tx_ref': txref,
          'uid': uid,
        }),
      );

      print('✅ Payment Confirmation Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Payment confirmed successfully');
        Navigator.of(context).pop(); // Close WebView
        await _fetchWalletBalance(); // Refresh wallet balance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful! Wallet has been updated.')),
        );
      } else {
        throw Exception('Payment confirmation failed');
      }
    } catch (e) {
      print('❌ Payment Confirmation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment confirmation failed. Please contact support.')),
      );
    }
  }

  Widget _buildOrderRequestsButton() {
    print('🔄 Building order requests button');
    print('Loading state: $_isLoading');
    print('Wallet balance: $_walletBalance ETB');

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 10),
            Text('Loading wallet...', 
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    }

    if (_walletBalance >= 1500) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderRequestsPage()),
          );
        },
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
            'Requests',
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
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
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
              colors: [Colors.black, Colors.grey.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
            padding: EdgeInsets.only(right: 16.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(FontAwesomeIcons.bars, color: Colors.white),
                onPressed: () {
                  setState(() => isDrawerOpen = true);
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
                  colors: [Colors.black, Colors.grey.shade800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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
                          ? Icon(FontAwesomeIcons.user, size: 40, color: Colors.grey)
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
                  Text(
                    'Hi, Driver!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(FontAwesomeIcons.user, 'Profile', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WalletPage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.shoppingCart, 'My Orders', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersPage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          DriverMapComponent(),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildOrderRequestsButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Function onTap) {
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
