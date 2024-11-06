import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final String chapaPaymentUrl;

  PaymentPage({required this.chapaPaymentUrl});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView(); // For Android compatibility
  }

  Future<void> _verifyPayment() async {
    try {
      final response = await http.get(
        Uri.parse('http://your-backend-url.com/api/verify-payment'),
      );

      if (response.statusCode == 200) {
        final verificationResult = response.body; // Parse JSON if needed
        if (verificationResult == "success") {
          Navigator.pop(context, "Payment verified!"); // Return to main page with success status
          // Optionally navigate to orders tab if part of main page UI
        } else {
          Navigator.pop(context, "Payment verification failed.");
        }
      } else {
        Navigator.pop(context, "Error in verification.");
      }
    } catch (error) {
      Navigator.pop(context, "Verification error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment'),
      ),
      body: WebView(
        initialUrl: widget.chapaPaymentUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        navigationDelegate: (NavigationRequest request) {
          if (request.url.contains("success")) {
            // If payment is successful, verify with backend
            _verifyPayment();
          } else if (request.url.contains("failure")) {
            Navigator.pop(context, "Payment failed!");
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}
