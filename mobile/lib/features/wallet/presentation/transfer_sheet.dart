import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';
import 'wallet_theme.dart';

const _unallocatedValue = '__unallocated__';

class TransferSheet extends StatefulWidget {
  final List<Allowance> allowances;
  const TransferSheet({super.key, required this.allowances});

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  final _amountController = TextEditingController();
  late String _fromId = widget.allowances.first.id;
  String _toId = _unallocatedValue;
  bool _submitting = false;

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
            items: [
              ...widget.allowances.map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} (₱${a.currentBalance.toStringAsFixed(0)})'),
                ),
              ),
              const DropdownMenuItem(
                value: _unallocatedValue,
                child: Text('Unallocated funds'),
              ),
            ],
            onChanged: (value) => setState(() => _fromId = value!),
          ),
          const SizedBox(height: 14),
          SheetDropdownField<String>(
            value: _toId,
            label: 'To',
            icon: Icons.arrow_downward_rounded,
            items: [
              const DropdownMenuItem(
                value: _unallocatedValue,
                child: Text('Unallocated funds'),
              ),
              ...widget.allowances.map(
                (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
              ),
            ],
            onChanged: (value) => setState(() => _toId = value!),
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
          SheetPrimaryButton(
            label: 'Confirm Transfer',
            loading: _submitting,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different places to transfer between.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<WalletProvider>();
    final success = await provider.transfer(
      fromAllowanceId: _fromId == _unallocatedValue ? null : _fromId,
      toAllowanceId: _toId == _unallocatedValue ? null : _toId,
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
