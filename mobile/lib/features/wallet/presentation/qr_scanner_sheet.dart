import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../domain/qr_model.dart';
import 'card_wallet_provider.dart';

class QrScannerSheet extends StatefulWidget {
  final String cardWalletId;
  const QrScannerSheet({super.key, required this.cardWalletId});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  bool _handled = false;
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, String>? _parse(String raw) {
    final parts = raw.split('|');
    if (parts.length < 2) return null;
    return {
      'provider': parts[0].toLowerCase(),
      'amount': parts[1],
      'merchant': parts.length > 2 ? parts[2] : '',
      'account': parts.length > 3 ? parts[3] : '',
    };
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final parsed = _parse(raw);
    if (parsed == null) return;

    setState(() => _handled = true);
    final amount = double.tryParse(parsed['amount']!) ?? 0;
    final provider = parsed['provider']!;

    final reservation = await context.read<CardWalletProvider>().reserveQr(
          cardWalletId: widget.cardWalletId,
          amount: amount,
          provider: provider,
          merchantName: parsed['merchant']!.isEmpty ? null : parsed['merchant'],
          destinationAccount: parsed['account']!.isEmpty ? null : parsed['account'],
          rawPayload: raw,
        );

    if (!mounted) return;
    if (reservation == null) {
      setState(() => _handled = false);
      final err = context.read<CardWalletProvider>().errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    Navigator.of(context).pop<QrReservation>(reservation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to Pay')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        // Surfaces the real reason the camera preview isn't showing
        // instead of the generic "!" placeholder icon.
              errorBuilder: (context, error, child) {
          return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Camera unavailable:\n${error.errorDetails?.message ?? error.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}