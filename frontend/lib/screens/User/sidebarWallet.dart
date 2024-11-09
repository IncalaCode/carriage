import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../login_screen.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double balance = 0.0;
  bool isLoading = true;
  String? _authToken;
  String? _paymentUrl;
  String? _txRef;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    try {
      await _loadAuthToken();
      if (mounted) {
        await fetchWalletBalance();
      }
    } catch (e) {
      print('❌ Initialization error: $e');
    }
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _authToken = prefs.getString('authToken');
        print('🔑 Loaded auth token: $_authToken');
      });
    }
  }

  Future<void> _initiatePayment() async {
    if (_authToken == null) {
      print('❌ No auth token available for payment');
      return;
    }

    try {
      print('💳 Initiating payment process...');
      final url = Uri.parse('${Config.baseUrl}/client/order/initiate-payment');
      print('🔗 Payment endpoint URL: $url');
      print('🔑 Using Authorization Header: $_authToken');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': _authToken,
        }),
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
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Payment Initiation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate payment. Please try again.')),
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
              print('🔄 Navigation to: ${request.url}');
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

  Future<void> _confirmPayment(String txref) async {
    try {
      print('✅ Confirming payment with backend...');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/client/order/confirm-payment'),
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
        
        // Fetch updated wallet balance
        await fetchWalletBalance();
        
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

  Future<void> fetchWalletBalance() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });
    
    if (_authToken == null) {
      print('❌ No auth token available');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      print('💰 Fetching wallet balance... $_authToken');
      final url = Uri.parse('${Config.baseUrl}/user/wallet/balance');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': _authToken,
        }),
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully decoded JSON data: $data');
        
        setState(() {
          balance = data['balance'] is String 
              ? double.parse(data['balance']) 
              : (data['balance'] as num).toDouble();
          isLoading = false;
        });
        print('💰 Updated balance to: $balance');
      } else {
        print('❌ Failed to fetch wallet balance: ${response.statusCode}');
        print('❌ Error response body: ${response.body}');
        throw Exception('Failed to load wallet balance: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching wallet balance: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Example data for recent transactions
  final List<Map<String, String>> recentTransactions = [
    {'amount': '\$200', 'date': 'Oct 5, 2024', 'type': 'withdrawal'},
    {'amount': '\$50', 'date': 'Oct 3, 2024', 'type': 'withdrawal'},
    {'amount': '\$150', 'date': 'Oct 1, 2024', 'type': 'deposit'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context); // Back functionality
          },
        ),
        title: Text('Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading 
              ? CircularProgressIndicator()
              : Text(
                  'Current Balance: ${balance.toStringAsFixed(2)} ETB',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
            SizedBox(height: 20),

            // Deposit Buttons with Gradient Backgrounds
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color.fromARGB(255, 0, 0, 0), const Color.fromARGB(255, 154, 131, 158)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ElevatedButton(
                      onPressed: _initiatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Deposit Money',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          

            SizedBox(height: 30),

            // Recent Transactions (Clickable to show all history)
            GestureDetector(
              onTap: () {
                // Navigate to transaction history page
                Navigator.pushNamed(context, '/transaction_history');
              },
              child: Text(
                'All Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 10),

            // Display recent 3 transactions in a table with icons
            Table(
              border: TableBorder.all(width: 1.0, color: Colors.grey),
              children: recentTransactions.map((transaction) {
                IconData transactionIcon = transaction['type'] == 'deposit'
                    ? FontAwesomeIcons.arrowDown
                    : FontAwesomeIcons.arrowUp;
                Color iconColor = transaction['type'] == 'deposit'
                    ? Colors.green
                    : Colors.red;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(transactionIcon, color: iconColor, size: 16),
                          SizedBox(width: 8),
                          Text(transaction['amount']!),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(transaction['date']!),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        transaction['type']!,
                        style: TextStyle(
                          color: transaction['type'] == 'deposit'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
          