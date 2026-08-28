import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'card_wallet_provider.dart';
import 'wallet_theme.dart';

class CardActionSheet extends StatefulWidget {
  final String cardWalletId;
  final bool isSpend;
  const CardActionSheet({super.key, required this.cardWalletId, required this.isSpend});

  @override
  State<CardActionSheet> createState() => _CardActionSheetState();
}

class _CardActionSheetState extends State<CardActionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: widget.isSpend ? 'Spend Allowance' : 'Add Allowance',
            icon: widget.isSpend ? Icons.remove_circle_rounded : Icons.add_circle_rounded,
            iconBg: widget.isSpend ? const Color(0xFFFFE3D1) : const Color(0xFFE1F5E0),
            iconFg: widget.isSpend ? const Color(0xFFD9772E) : WalletPalette.primaryStart,
          ),
          SheetTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            label: 'Amount (PHP)',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 14),
          SheetTextField(
            controller: _descriptionController,
            label: 'Description (optional)',
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 24),
          SheetPrimaryButton(
            label: widget.isSpend ? 'Confirm Expense' : 'Add Funds',
            loading: _submitting,
            colors: widget.isSpend
                ? const [Color(0xFFD9772E), Color(0xFFF0AE3F)]
                : const [WalletPalette.primaryStart, WalletPalette.primaryEnd],
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _submitting = true);
    final provider = context.read<CardWalletProvider>();
    final description =
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
    final success = widget.isSpend
        ? await provider.spend(cardWalletId: widget.cardWalletId, amount: amount, description: description)
        : await provider.addAllowance(cardWalletId: widget.cardWalletId, amount: amount, description: description);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }
}