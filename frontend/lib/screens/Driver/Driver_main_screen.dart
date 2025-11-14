import 'package:My_truck/screens/User/Order_form_screen.dart';
import 'package:My_truck/screens/User/main_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config.dart';
//import '../login_screen.dart';
import 'OrderRequestsPage.dart';
import 'sidebarProfiledriver.dart';
import 'sidebarWalletdriver.dart';
import 'sidebarMyOrderdriver.dart';
import 'sidebarSettingsdriver.dart';
import './Driver_map/driver_map_component.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

late BuildContext cont;
late Function(bool) function;

late BuildContext cont;
late Function(bool) function;

class DriverMainScreen extends StatefulWidget {
  @override
  _DriverMainScreenState createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _profileImage;
  String? _authToken;
  // double _walletBalance = 0.0;
  // bool _isLoading = true;
  double _walletBalance = 1600.0;
  bool _isLoading = false;
  double _walletBalance = 0.0;
  bool _isLoading = true;

  String? _paymentUrl;
  String? _txRef;
  bool is_tracking = false;

   String?  username = "";
   String? image = "";
   bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    print('🚀 Initializing Driver Main Screen');
    _initializeScreen();
    cont = context;
    function = change;
    checkData();
    _checkConnectivity();
  }

  void change(bool value) {
    setState(() {
      is_tracking = value;
    });
  }

  Future<void> checkData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('username')) {
      showUserInfoBottomSheet(
        cont,
        {
          "name": prefs.getString('username') ?? "unknown",
          "phone": prefs.getString('userphone') ?? "123-456-7890",
          "locked": true,
          "from": prefs.getString('userfrom') ?? '' ?? "unknown",
          "material_type": prefs.getString('usermaterial_type') ?? "unknown",
          "destination": prefs.getString('userdestination') ?? "unknown",
        },
      );
    }
      username = await prefs.getString("username") ?? "";
      image = await prefs.getString("user_image") ??  "";
       print('Image URL: ${image != null && image!.isNotEmpty ? Config.imagebaseUrl + image! : 'No image available'}');

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
      print('💰 Fetching wallet balance... $_authToken');
      final url = Uri.parse('${Config.baseUrl}/driver/wallet/balance');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': _authToken,
        }),
      );

      // if(response.statusCode == 404){
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => DriverMainScreen()),
      //   );
      // }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💰 Wallet balance received: ${data['balance']}');
        
        if (mounted) {
          setState(() {
            _walletBalance = double.parse(data['balance'].toString());
            _isLoading = false;
          });
        }
      } else {
        print('❌ Failed to fetch wallet balance: ${response.statusCode}');
        print('Failed to load wallet balance: ${response.body}');
        throw Exception('Failed to load wallet balance: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching wallet balance: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (_authToken == null) {
      print('❌ No auth token available for payment');
      return;
    }

    try {
      print('💳 Initiating payment process...');
      final url =
          Uri.parse('${Config.baseUrl}/driver/request/initiate-payment');
      print('🔗 Payment endpoint URL: $url');
      print('🔑 Using Authorization Header: $_authToken');

      final value = json.encode({
        'token': _authToken,
      });
      print('🔑 Using Authorization Header: $value');

      final response = await http.post(
        url, // Make sure to parse the URL into a Uri object
        headers: {
          'Content-Type': 'application/json',
        },
        body: value,
      );

      print('💳 Payment Initiation Response Status: ${response.statusCode}');
      print('💳 Payment Initiation Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔗 Payment URL Received: ${data['payment_url']}');
        print('🔗 Payment URL Received: ${data['tx_ref']}');
        setState(() {
          _paymentUrl = data['payment_url'];
          _txRef = data['tx_ref'];
        });
        _showPaymentWebView();
      } else {
        print('❌ Error Response: ${response.body}');
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Payment Initiation Error: $e');
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
        leading: IconButton(
          icon: Icon(FontAwesomeIcons.xmark),
          color: const Color.fromARGB(255, 0, 0, 0),
          onPressed: () => Navigator.pop(context),
        ),
      ),
          body: WebView(
            initialUrl: _paymentUrl,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              print('🔄 Navigation to: ${request.url}');
              //Navigator.pop(context);
              _confirmPayment(_txRef!);
              return NavigationDecision.prevent;
            },
            onWebResourceError: (WebResourceError error) {
              print('🚨 Web Resource Error: ${error.description}');
            },
          ),
        ),
      ),
    );
  }
    void _showPaymentNotification(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3), // Duration for the SnackBar
      ),
    );
  }

  Future<void> _confirmPayment(String txref) async {
    try {
      print('✅ Confirming payment with backend...');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/request/confirm-payment'),
        headers: {  
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tx_ref': txref,
          'token': _authToken!,
        }),
      );

      print('✅ Payment Confirmation Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Payment confirmed successfully');
        Navigator.pop(context); // Close WebView
        await _fetchWalletBalance(); // Refresh wallet balance
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment successful! Wallet has been updated.')),
        );
         
      } else {
        throw Exception('Payment confirmation failed');
      }
    } catch (e) {
      print('❌ Payment Confirmation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Payment confirmation failed. Please contact support.')),
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
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // If balance is sufficient, show green button for OrderRequests
    if (_walletBalance >= 1500) {
      return FloatingActionButton.extended(
        onPressed: () {
          is_tracking
              ? checkData()
              : Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderRequestsPage()),
                );
        },
        backgroundColor: Colors.green, // Changed to green for sufficient balance
        icon: Icon(FontAwesomeIcons.bell, color: Colors.white),
        label: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500], // Green gradient
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(

            is_tracking ? 'locked request' : 'Requests',

            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } 
    // If balance is insufficient, show red button for payment
    else {
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

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
      });
    } else {
      setState(() {
        _isOffline = false;
      });
    }

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _isOffline = true;
        });
      } else {
        setState(() {
          _isOffline = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                  // Debugging: Print the image URL to the console
                 
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: image != null && image!.isNotEmpty
                        ? NetworkImage(Config.imagebaseUrl +"/storage/"+ image!)
                        : AssetImage('path/to/placeholder/image.png') as ImageProvider, // Provide a placeholder image path
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
                        username!,
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
                  _buildDrawerItem(FontAwesomeIcons.user, 'Profile', context, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePagedriver()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', context, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WalletDriverPage()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.shoppingCart, 'My Orders', context, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersPagedriver()));
                  }),
                  _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', context, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPagedriver()));
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
            top: 30,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF9A839E)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                mini: true,
                child: Icon(
                  FontAwesomeIcons.bars,
                  color: Colors.white,
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
          ),

          
          Positioned(
            top: 30,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF9A839E)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/NewLogo.png',
                height: 50,
              ),
            ),
          ),

          
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildOrderRequestsButton(),
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: EdgeInsets.all(8),
                child: Text(
                  'You are currently offline. Please check your internet connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
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


void showUserInfoBottomSheet(
    BuildContext context, Map<String, dynamic> userData) {
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', userData['name']);
    await prefs.setString('userphone', userData['phone']);
    await prefs.setString('userfrom', userData['from']);
    await prefs.setString('usermaterial_type', userData['material_type']);
    await prefs.setString('userdestination', userData['destination']);
  }



  saveData();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.5, // Takes half the screen height
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Indicator at the top of the bottom sheet
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Driver-oriented user information layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(thickness: 1.0, height: 16),
                    buildDetailRow(
                        FontAwesomeIcons.person, "Name", userData['name']),
                    const SizedBox(height: 8),
                    buildDetailRow(
                        FontAwesomeIcons.phone, "Phone", userData['phone']),
                    const SizedBox(height: 8),
                    buildDetailRow(FontAwesomeIcons.lock, "Locked",
                        userData['locked'] ? "Yes" : "No"),
                    const SizedBox(height: 8),
                    buildDetailRow(
                        FontAwesomeIcons.locationDot, "From", userData['from']),
                    const SizedBox(height: 8),
                    buildDetailRow(FontAwesomeIcons.cartShopping,
                        "Material Type", userData['material_type']),
                    const SizedBox(height: 8),
                    buildDetailRow(FontAwesomeIcons.flag, "Destination",
                        userData['destination']),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        cancelRequest(cont);
                        if (!is_tracking) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Center(
                        child: Text(
                        child:  Text(
                          "cancel Request",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget buildDetailRow(IconData icon, String label, String? value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, color: Colors.blueGrey, size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          "$label: ${value ?? 'Unknown'}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ],
  );
}

void cancelRequest(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Warning"),
        content: const Text(
            "If you proceed, the cancellation fee will be deducted from your wallet. Are you sure you want to cancel this request?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog without action
            },
            child: const Text("No, Go Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Red color for emphasis
            ),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _proceedWithCancellation(context); // Proceed with cancellation
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      );
    },
  );
}

void _proceedWithCancellation(BuildContext context) async {
  final response = await http.post(
    Uri.parse('${Config.baseUrl}/driver/request/confirm-payment'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      "cancel": true,
      'token': getToken(),
    }),
  );

  if (response.statusCode == 200) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Request has been canceled and wallet updated.")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("There were proble in the requst pls try again .")),
    );
  }
}

