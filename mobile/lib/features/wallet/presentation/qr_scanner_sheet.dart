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

  // TODO: replace with real EMVCo/QR Ph payload parsing. Stub format
  // assumed for now: "provider|amount|merchant|account".
  // Flag for whoever owns the QR Ph payload spec.
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
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}