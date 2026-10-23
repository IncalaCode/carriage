import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../login_screen.dart';

class WalletDriverPage extends StatefulWidget {
  @override
  _WalletDriverPageState createState() => _WalletDriverPageState();
}

class _WalletDriverPageState extends State<WalletDriverPage> {
  double balance = 0.0;
  bool isLoading = true;
  String? _authToken;
  String? _paymentUrl;
  String? _txRef;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    print('🚀 initState called');
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    try {
      print('🏁 Starting wallet initialization');
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
      final url = Uri.parse('${Config.baseUrl}/driver/request/initiate-payment');
      print('🔗 Payment endpoint URL: $url');
      print('🔑 Using Authorization Header: $_authToken');

      final value = json.encode({
        'token': _authToken,
      });
      print('🔑 Using Authorization Header: $value');

      final response = await http.post(
        url,
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
      print('💰 Fetching wallet balance and transactions... $_authToken');
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
          
          if (data['transactions'] != null) {
            transactions = List<Map<String, dynamic>>.from(data['transactions'].map((tx) => {
              'amount': tx['amount'].toString(),
              'date': DateTime.parse(tx['created_at']).toString().split(' ')[0],
              'type': tx['type'],
              'status': tx['status'] ?? 'Unknown',
            }));

            recentTransactions = transactions.take(3).toList();
          }
          
          isLoading = false;
        });
        print('💰 Updated balance to: $balance');
        print('📊 Updated transactions: $transactions');
      } else {
        throw Exception('Failed to load wallet balance: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching wallet data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildRecentTransactionTable() {
    if (recentTransactions.isEmpty) {
      return Center(child: Text('No recent transactions found'));
    }

    return Table(
      border: TableBorder.all(width: 1.0, color: Colors.grey),
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Amount'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Date'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Type'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Status'),
            ),
          ],
        ),
        ...recentTransactions.map((transaction) {
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
                    Text('${transaction['amount']}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(transaction['date']),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  transaction['type'],
                  style: TextStyle(
                    color: transaction['type'] == 'deposit'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  transaction['status'] ?? 'Unknown',
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Add this method to show the withdrawal dialog
  void _showWithdrawDialog() {
    double availableAmount = balance - 1500; // Calculate available amount for withdrawal
    TextEditingController accountNameController = TextEditingController();
    TextEditingController accountNumberController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Withdraw Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Balance: ${balance.toStringAsFixed(2)} ETB'),
              Text('Available Amount for Withdrawal: ${availableAmount.toStringAsFixed(2)} ETB'),
              TextField(
                controller: accountNameController,
                decoration: InputDecoration(labelText: 'Account Name'),
              ),
              TextField(
                controller: accountNumberController,
                decoration: InputDecoration(labelText: 'Account Number'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Handle withdrawal logic here
                double amountToWithdraw = double.tryParse(amountController.text) ?? 0;
                if (amountToWithdraw > 0 && amountToWithdraw <= availableAmount) {
                  // Call the backend API to process the withdrawal
                  await _processWithdrawal(accountNameController.text, accountNumberController.text, amountToWithdraw);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid withdrawal amount.')),
                  );
                double amountToWithdraw = double.tryParse(amountController.text) ?? 0;
                if (amountToWithdraw > 0 && amountToWithdraw <= availableAmount) {
                  Navigator.of(context).pop(); // Close the dialog before processing withdrawal
                  await _processWithdrawal(accountNameController.text, accountNumberController.text, amountToWithdraw);
                } else {
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid withdrawal amount.')),
                    );
                  }
                }
              },
              child: Text('Withdraw'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to process the withdrawal
  Future<void> _processWithdrawal(String accountName, String accountNumber, double amount) async {
    try {
      print('💳 Processing withdrawal of $amount ETB to $accountName ($accountNumber)');
      // Call your backend API here
  // Update the _processWithdrawal method to handle confirmation
  Future<void> _processWithdrawal(String accountName, String accountNumber, double amount) async {
    try {
      // Convert the amount to an integer or a string without decimal places
      int formattedAmount = amount.toInt(); // or use amount.toString() if you prefer a string

      print('💳 Processing withdrawal of $formattedAmount ETB to $accountName ($accountNumber)');
      
      // Print the data being sent to the backend for debugging
      final withdrawalData = {
        'token': _authToken,
        'account_name': accountName,
        'account_number': accountNumber,
        'amount': formattedAmount, // Use the formatted amount here
      };
      print('📤 Withdrawal Data: $withdrawalData');

      // Call your backend API here
            print('💰 Fetching wallet balance and transactions... $_authToken');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/driver/request/withdraw'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': _authToken,
          'account_name': accountName,
          'account_number': accountNumber,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Withdrawal successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal in progress.')),
        );
        // Optionally, refresh wallet balance
        await fetchWalletBalance();
      } else {
        body: json.encode(withdrawalData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Ensure that the response contains the expected keys
        if (data.containsKey('message')) {
          print('✅ Withdrawal successful: ${data['message']}');
          
          // Show feedback to the user only if the widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Withdrawal successful! ${data['message']}')),
            );
          }
        } else {
          print('❌ Withdrawal successful but no message found in response: $data');
        }

        // Fetch updated wallet balance
        await fetchWalletBalance(); // Update the wallet balance
      } else {
        print('❌ Withdrawal Error: ${response.body}'); // Print error response for debugging
        throw Exception('Failed to process withdrawal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Withdrawal Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing withdrawal. Please try again.')),
      );
      // Show error message only if the widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing withdrawal. Please try again.')),
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
            Navigator.pop(context); // Back functionality
          },
        ),
        title: Text('Wallet Driver'),
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
                SizedBox(width: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color.fromARGB(255, 0, 0, 0), const Color.fromARGB(255, 154, 131, 158)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ElevatedButton(
                      onPressed: _showWithdrawDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Withdraw Money',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,),

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

            // Display recent transactions in a table with icons
            buildRecentTransactionTable(),
          ],
        ),
      ),
    );
  }
}
          