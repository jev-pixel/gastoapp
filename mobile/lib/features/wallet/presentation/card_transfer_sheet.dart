import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/card_wallet_model.dart';
import 'card_wallet_provider.dart';
import 'wallet_theme.dart';

const _physicalValue = '__physical__';

class CardTransferSheet extends StatefulWidget {
  final List<CardWallet> cardWallets;
  final String? initialCardWalletId; // preselects "From" if opened from a specific card dashboard
  const CardTransferSheet({super.key, required this.cardWallets, this.initialCardWalletId});

  @override
  State<CardTransferSheet> createState() => _CardTransferSheetState();
}

class _CardTransferSheetState extends State<CardTransferSheet> {
  final _amountController = TextEditingController();
  late String _fromId = widget.initialCardWalletId ?? _physicalValue;
  late String _toId = _fromId == _physicalValue && widget.cardWallets.isNotEmpty
      ? widget.cardWallets.first.id
      : _physicalValue;
  bool _submitting = false;

  List<DropdownMenuItem<String>> get _allOptions => [
        const DropdownMenuItem(value: _physicalValue, child: Text('Physical Wallet')),
        ...widget.cardWallets.map(
          (c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (₱${c.currentBalance.toStringAsFixed(0)})')),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(
            title: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            iconBg: Color(0xFFDCEBFF),
            iconFg: Color(0xFF2E6ADE),
          ),
          SheetDropdownField<String>(
            value: _fromId,
            label: 'From',
            icon: Icons.arrow_upward_rounded,
            items: _allOptions,
            onChanged: (v) => setState(() => _fromId = v!),
          ),
          const SizedBox(height: 14),
          SheetDropdownField<String>(
            value: _toId,
            label: 'To',
            icon: Icons.arrow_downward_rounded,
            items: _allOptions,
            onChanged: (v) => setState(() => _toId = v!),
          ),
          const SizedBox(height: 14),
          SheetTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            label: 'Amount (PHP)',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 24),
          SheetPrimaryButton(label: 'Confirm Transfer', loading: _submitting, onTap: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different wallets to transfer between.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<CardWalletProvider>();
    final success = await provider.transfer(
      fromCardWalletId: _fromId == _physicalValue ? null : _fromId,
      fromPhysical: _fromId == _physicalValue,
      toCardWalletId: _toId == _physicalValue ? null : _toId,
      toPhysical: _toId == _physicalValue,
      amount: amount,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }
}