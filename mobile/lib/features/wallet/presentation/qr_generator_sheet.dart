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
          FadeSlideIn(
            child: SheetTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              label: 'Amount (PHP) — optional',
              icon: Icons.payments_outlined,
              prefixText: '₱ ',
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft radial glow behind the code, like a card catching
                  // light, instead of the QR sitting on bare white.
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          WalletPalette.accentBlueEnd.withOpacity(0.10),
                          WalletPalette.accentBlueEnd.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WalletPalette.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      // AnimatedSwitcher gives a soft cross-fade + scale
                      // whenever the amount changes the payload, instead of
                      // the code silently repainting mid-frame.
                      child: AnimatedSwitcher(
                        duration: WalletMotion.standard,
                        switchInCurve: WalletMotion.settle,
                        switchOutCurve: WalletMotion.settle,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
                        ),
                        child: QrImageView(
                          key: ValueKey(payload),
                          data: payload,
                          size: 208,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 110),
            child: Center(
              child: Text(
                'Have the sender scan this in their banking app',
                style: TextStyle(color: WalletPalette.textMuted, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
