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
                      onPressed: () {
                        // Deposit via CBE functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Deposit via CBE',
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
                      onPressed: () {
                        // Deposit via Telebirr functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Deposit via Telebirr',
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
          