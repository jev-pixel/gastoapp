import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Transfer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _fromId,
            decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
            items: [
              ...widget.allowances.map(
                (a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (₱${a.currentBalance.toStringAsFixed(0)})')),
              ),
              const DropdownMenuItem(value: _unallocatedValue, child: Text('Unallocated funds')),
            ],
            onChanged: (value) => setState(() => _fromId = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _toId,
            decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: _unallocatedValue, child: Text('Unallocated funds')),
              ...widget.allowances.map(
                (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
              ),
            ],
            onChanged: (value) => setState(() => _toId = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (PHP)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirm Transfer'),
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