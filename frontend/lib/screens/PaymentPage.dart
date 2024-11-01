import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentPage extends StatefulWidget {
  String chapaPaymentUrl = 'http://checkout.chapa.co/checkout/web/payment/PL-YL2U746UyzJE';

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
            Navigator.pop(context, "Payment successful!");
          } else if (request.url.contains("failure")) {
            Navigator.pop(context, "Payment failed!");
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}
