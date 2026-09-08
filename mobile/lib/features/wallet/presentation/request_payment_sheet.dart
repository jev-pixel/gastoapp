import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../domain/card_wallet_model.dart';
import 'card_wallet_provider.dart';
import 'wallet_theme.dart';

/// Replaces the old QR-generator flow. GastoApp cannot legitimately issue
/// a real, payable QR Ph code — that requires BSP/PPMI participant
/// registration, not just following the TLV format — so instead of
/// faking one, this screen helps the wallet owner request a payment: it
/// surfaces their real proxy (mobile number / account / email) as
/// copyable text, and points them to their own banking app for the
/// actual QR.
class RequestPaymentSheet extends StatefulWidget {
  final CardWallet wallet;
  const RequestPaymentSheet({super.key, required this.wallet});

  @override
  State<RequestPaymentSheet> createState() => _RequestPaymentSheetState();
}

class _RequestPaymentSheetState extends State<RequestPaymentSheet> {
  late final _proxyController = TextEditingController(text: widget.wallet.receiveProxy ?? '');
  final _amountController = TextEditingController();
  late bool _editingProxy = (widget.wallet.receiveProxy == null || widget.wallet.receiveProxy!.isEmpty);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _proxyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveProxy() async {
    final value = _proxyController.text.trim();
    if (value.isEmpty) return;
    setState(() => _saving = true);
    final provider = context.read<CardWalletProvider>();
    final success = await provider.updateReceiveProxy(id: widget.wallet.id, receiveProxy: value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) _editingProxy = false;
    });
    if (!success && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<CardWalletProvider>().byId(widget.wallet.id) ?? widget.wallet;
    final proxy = wallet.receiveProxy;
    final amount = double.tryParse(_amountController.text);
    final requestMessage = (proxy == null || proxy.isEmpty)
        ? null
        : 'Please send ${(amount != null && amount > 0) ? '₱${amount.toStringAsFixed(2)}' : 'the amount'} '
          'to my ${wallet.provider} ($proxy).';

    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(
            title: 'Request Payment',
            icon: Icons.call_received_rounded,
            iconBg: Color(0xFFDCEBFF),
            iconFg: Color(0xFF2E6ADE),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WalletPalette.amberStart.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WalletPalette.glassBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: WalletPalette.amberStart),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "GastoApp can't generate a real payable QR — open your "
                    "${wallet.provider} app to show its own QR, or share your "
                    "details below.",
                    style: const TextStyle(fontSize: 12.5, color: WalletPalette.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_editingProxy) ...[
            SheetTextField(
              controller: _proxyController,
              label: '${wallet.provider} mobile number / account / email',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 6),
            Text(
              "Saved once, so you won't have to enter it again here.",
              style: TextStyle(fontSize: 12, color: WalletPalette.textMuted),
            ),
            const SizedBox(height: 16),
            SheetPrimaryButton(label: 'Save', loading: _saving, onTap: _saveProxy),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WalletPalette.glassBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.provider.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: WalletPalette.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(proxy ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () => _copy(proxy ?? '', 'Number'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => setState(() => _editingProxy = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SheetTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              label: 'Amount to request (optional)',
              icon: Icons.payments_outlined,
              prefixText: '₱ ',
            ),
            if (requestMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WalletPalette.canvasTop,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WalletPalette.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requestMessage, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _copy(requestMessage, 'Message'),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy message'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}