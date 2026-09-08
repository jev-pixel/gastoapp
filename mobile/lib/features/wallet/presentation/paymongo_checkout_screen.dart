import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum CheckoutOutcome { success, cancelled, pending }

/// Hosts PayMongo's checkout page. The backend webhook is the actual
/// source of truth for settlement — this screen's job is just to give
/// the user somewhere to authorize the payment and to notice when
/// they've reached the success/cancel redirect, so GastoApp can close
/// this view and refresh without needing a real hosted "thank you" page.
class PaymongoCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  const PaymongoCheckoutScreen({super.key, required this.checkoutUrl});

  @override
  State<PaymongoCheckoutScreen> createState() => _PaymongoCheckoutScreenState();
}

class _PaymongoCheckoutScreenState extends State<PaymongoCheckoutScreen> {
  late final WebViewController _controller;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;
            if (uri.path.contains('/paymongo/success')) {
              _finish(CheckoutOutcome.success);
              return NavigationDecision.prevent;
            }
            if (uri.path.contains('/paymongo/cancel')) {
              _finish(CheckoutOutcome.cancelled);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _finish(CheckoutOutcome outcome) {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish(CheckoutOutcome.pending);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _finish(CheckoutOutcome.cancelled),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}