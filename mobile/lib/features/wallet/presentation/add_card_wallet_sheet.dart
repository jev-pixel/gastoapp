import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/card_wallet_model.dart';
import 'card_wallet_provider.dart';
import 'wallet_theme.dart';

class AddCardWalletSheet extends StatefulWidget {
  const AddCardWalletSheet({super.key});

  @override
  State<AddCardWalletSheet> createState() => _AddCardWalletSheetState();
}

class _AddCardWalletSheetState extends State<AddCardWalletSheet> {
  String _provider = cardProviders.first;
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(
            title: 'Add Card Wallet',
            icon: Icons.credit_card_rounded,
            iconBg: Color(0xFFDCEBFF),
            iconFg: Color(0xFF2E6ADE),
          ),
          SheetDropdownField<String>(
            value: _provider,
            label: 'Provider',
            icon: Icons.account_balance_rounded,
            items: cardProviders.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _provider = v!),
          ),
          const SizedBox(height: 14),
          SheetTextField(
            controller: _nameController,
            label: 'Wallet name (e.g. "My GCash")',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 14),
          SheetTextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            label: 'Starting balance (PHP)',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 6),
          Text(
            "If this balance is actually cash you already have in your physical wallet, "
            "leave this at 0 and use Transfer instead once the card wallet is created — "
            "that keeps both balances accurate.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
          ),
          const SizedBox(height: 24),
          SheetPrimaryButton(
            label: 'Create Card Wallet',
            loading: _submitting,
            colors: const [WalletPalette.accentBlueStart, WalletPalette.accentBlueEnd],
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give this card wallet a name.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final provider = context.read<CardWalletProvider>();
    final success = await provider.createCardWallet(
      provider: _provider,
      name: name,
      currentBalance: balance,
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