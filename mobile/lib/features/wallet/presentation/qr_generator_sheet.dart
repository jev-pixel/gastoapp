import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../domain/card_wallet_model.dart';
import 'wallet_theme.dart';

class QrGeneratorSheet extends StatefulWidget {
  final CardWallet wallet;
  const QrGeneratorSheet({super.key, required this.wallet});

  @override
  State<QrGeneratorSheet> createState() => _QrGeneratorSheetState();
}

class _QrGeneratorSheetState extends State<QrGeneratorSheet> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild the QR payload live as the amount changes.
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final payload = '${widget.wallet.provider.toLowerCase()}|$amount|${widget.wallet.name}|';

    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(
            title: 'Receive via QR',
            icon: Icons.qr_code_2_rounded,
            iconBg: Color(0xFFDCEBFF),
            iconFg: Color(0xFF2E6ADE),
          ),
          SheetTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            label: 'Amount (PHP) — optional',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 20),
          Center(
            child: QrImageView(data: payload, size: 220, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Have the sender scan this in their banking app',
              style: TextStyle(color: WalletPalette.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}