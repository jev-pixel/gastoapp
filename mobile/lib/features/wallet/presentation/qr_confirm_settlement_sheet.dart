import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/qr_model.dart';
import 'card_wallet_provider.dart';
import 'wallet_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class QrConfirmSettlementSheet extends StatefulWidget {
  final QrReservation reservation;
  const QrConfirmSettlementSheet({super.key, required this.reservation});

  @override
  State<QrConfirmSettlementSheet> createState() => _QrConfirmSettlementSheetState();
}

class _QrConfirmSettlementSheetState extends State<QrConfirmSettlementSheet> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _confirming = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Ticks once a second purely to redraw the countdown text — the actual
    // expiry truth lives server-side (checked again on settle), this is
    // just so the user isn't staring at a static number.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final diff = widget.reservation.expiresAt.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    if (_remaining == Duration.zero) return 'Expired';
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s left';
  }

  Future<void> _confirmSettlement() async {
    setState(() => _confirming = true);
    final provider = context.read<CardWalletProvider>();
    final success = await provider.confirmQrSettlement(widget.reservation.id);
    if (!mounted) return;
    setState(() => _confirming = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of ${_currency.format(widget.reservation.amount)} confirmed.')),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  Future<void> _cancelReservation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel this reservation?'),
        content: const Text(
          "This releases the held funds back to your card wallet's available balance. "
          "Only do this if the payment did NOT go through.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep Waiting')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: WalletPalette.danger),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    await context.read<CardWalletProvider>().cancelQrReservation(widget.reservation.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final expired = _remaining == Duration.zero;
    final busy = _confirming || _cancelling;

    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(
            title: 'Confirm Payment',
            icon: Icons.hourglass_top_rounded,
            iconBg: Color(0xFFFFF2C2),
            iconFg: Color(0xFFB98A16),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WalletPalette.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.merchantName?.isNotEmpty == true ? r.merchantName! : r.provider.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: WalletPalette.ink),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (expired ? WalletPalette.danger : WalletPalette.amberStart).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _countdownLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: expired ? WalletPalette.danger : WalletPalette.amberStart,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currency.format(r.amount),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: WalletPalette.ink),
                ),
                if (r.destinationAccount?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'To: ${r.destinationAccount}',
                    style: const TextStyle(color: WalletPalette.textMuted, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            expired
                ? "This reservation expired and the hold on your funds has been released. You'll need to scan again."
                : "We've opened ${r.provider} and staged the details on your clipboard. Once you've sent the payment there, confirm it below so your card wallet balance updates.",
            style: const TextStyle(fontSize: 12.5, color: WalletPalette.textMuted, height: 1.4),
          ),
          const SizedBox(height: 22),
          SheetPrimaryButton(
            label: 'I Completed the Payment',
            loading: _confirming,
            onTap: (expired || busy) ? null : _confirmSettlement,
          ),
          const SizedBox(height: 10),
          if (!expired)
            TextButton.icon(
              onPressed: busy ? null : _cancelReservation,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(_cancelling ? 'Cancelling…' : "Didn't go through — Cancel"),
              style: TextButton.styleFrom(
                foregroundColor: WalletPalette.danger,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }
}