import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WalletPage extends StatelessWidget {
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
            Text(
              'Current Balance: \$1000',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Deposit Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Deposit via CBE functionality
                  },
                  child: Text('Deposit'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Deposit via Telebirr functionality
                  },
                  child: Text('Deposit via CBE'),
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
                'Recent Transactions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 10),

            // Display recent 3 transactions in a table
            Table(
              border: TableBorder.all(width: 1.0, color: Colors.grey),
              children: recentTransactions.map((transaction) {
                return TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(transaction['amount']!),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(transaction['date']!),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(transaction['type']!), // Access the type correctly
                  ),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
