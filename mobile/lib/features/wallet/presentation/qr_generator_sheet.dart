import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../domain/card_wallet_model.dart';
import 'qr_ph_builder.dart';
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
    // The backend's QrReserveRequest requires amount > 0 (Field(gt=0)) —
    // a QR generated with amount 0 would always fail to reserve when
    // scanned, so we gate rendering on a valid amount instead of letting
    // the user generate a code that's guaranteed to fail downstream.
    final isValid = amount > 0;
    // Builds a spec-valid EMVCo/QR Ph payload (correct TLV + CRC) rather
    // than the old pipe-delimited test string. This round-trips through
    // QrPhParser cleanly — including passing CRC verification — so a
    // GastoApp phone scanning another GastoApp-generated code works. It's
    // still NOT interoperable with real GCash/Maya/bank scanners, since
    // GastoApp doesn't hold a registered participant GUID; see the doc
    // comment on QrPhBuilder for details.
    final payload = isValid
        ? QrPhBuilder.build(
            cardWalletId: widget.wallet.id,
            merchantName: widget.wallet.name,
            amount: amount,
          )
        : '';

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
              label: 'Amount (PHP)',
              icon: Icons.payments_outlined,
              prefixText: '₱ ',
            ),
          ),
          const SizedBox(height: 6),
          FadeSlideIn(
            child: Text(
              'An amount is required — GastoApp reserves this amount in the '
              "sender's wallet before they pay you.",
              style: TextStyle(fontSize: 12, color: WalletPalette.textMuted, height: 1.3),
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
                          WalletPalette.accentBlueEnd.withValues(alpha: 0.10),
                          WalletPalette.accentBlueEnd.withValues(alpha: 0),
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
                            color: Colors.black.withValues(alpha: 0.06),
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
                        child: isValid
                            ? QrImageView(
                                key: ValueKey(payload),
                                data: payload,
                                size: 208,
                                backgroundColor: Colors.white,
                              )
                            : SizedBox(
                                key: const ValueKey('empty'),
                                width: 208,
                                height: 208,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_2_rounded, size: 40, color: WalletPalette.textFaint),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'Enter an amount above to generate your QR code',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12.5, color: WalletPalette.textMuted, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
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
                'Have the sender scan this from their GastoApp Scan to Pay screen',
                style: TextStyle(color: WalletPalette.textMuted, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}