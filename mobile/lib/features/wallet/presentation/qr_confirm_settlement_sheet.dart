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

class _QrConfirmSettlementSheetState extends State<QrConfirmSettlementSheet>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _confirming = false;
  bool _cancelling = false;

  // Slow breathing pulse on the countdown chip — a quiet "this is live"
  // cue instead of a static badge, dialed back once time actually runs low.
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

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
    _pulseController.dispose();
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
    final urgent = !expired && _remaining.inSeconds <= 30;

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
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: WalletPalette.glassBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.merchantName?.isNotEmpty == true ? r.merchantName! : r.provider.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: WalletPalette.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CountdownChip(
                        label: _countdownLabel,
                        expired: expired,
                        urgent: urgent,
                        pulse: _pulseController,
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
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: AnimatedSwitcher(
              duration: WalletMotion.standard,
              switchInCurve: WalletMotion.settle,
              child: Text(
                expired
                    ? "This reservation expired and the hold on your funds has been released. You'll need to scan again."
                    : "We've opened ${r.provider} and staged the details on your clipboard. Once you've sent the payment there, confirm it below so your card wallet balance updates.",
                key: ValueKey(expired),
                style: const TextStyle(fontSize: 12.5, color: WalletPalette.textMuted, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 110),
            child: SheetPrimaryButton(
              label: 'I Completed the Payment',
              loading: _confirming,
              onTap: (expired || busy) ? null : _confirmSettlement,
            ),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: !expired
                ? TextButton.icon(
                    onPressed: busy ? null : _cancelReservation,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(_cancelling ? 'Cancelling…' : "Didn't go through — Cancel"),
                    style: TextButton.styleFrom(
                      foregroundColor: WalletPalette.danger,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  )
                : TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Countdown pill with a quiet breathing pulse while time remains, and a
/// smooth color hand-off (amber → red → done) instead of an instant swap.
class _CountdownChip extends StatelessWidget {
  const _CountdownChip({
    required this.label,
    required this.expired,
    required this.urgent,
    required this.pulse,
  });

  final String label;
  final bool expired;
  final bool urgent;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final color = expired
        ? WalletPalette.danger
        : urgent
            ? WalletPalette.danger
            : WalletPalette.amberStart;

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        // Only breathe while there's still time and it isn't urgent yet —
        // once it's urgent the color carries the tension instead.
        final scale = (!expired && !urgent) ? 1.0 + (pulse.value * 0.05) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: WalletMotion.standard,
        curve: WalletMotion.settle,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedDefaultTextStyle(
          duration: WalletMotion.standard,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          child: Text(label),
        ),
      ),
    );
  }
}