import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../expenses/domain/expense_model.dart';
import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

const _unallocatedValue = '__unallocated__';

class SpendSheet extends StatefulWidget {
  final List<Allowance> allowances;
  const SpendSheet({super.key, required this.allowances});

  @override
  State<SpendSheet> createState() => _SpendSheetState();
}

class _SpendSheetState extends State<SpendSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.wants;
  late String _sourceId = widget.allowances.isNotEmpty ? widget.allowances.first.id : _unallocatedValue;
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
          const Text('Spend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _sourceId,
            decoration: const InputDecoration(labelText: 'Pay from', border: OutlineInputBorder()),
            items: [
              ...widget.allowances.map(
                (a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (₱${a.currentBalance.toStringAsFixed(0)} left)')),
              ),
              const DropdownMenuItem(value: _unallocatedValue, child: Text('Unallocated funds')),
            ],
            onChanged: (value) => setState(() => _sourceId = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (PHP)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: ExpenseCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
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
                : const Text('Confirm Expense'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _submitting = true);
    final provider = context.read<WalletProvider>();
    final success = await provider.spend(
      allowanceId: _sourceId == _unallocatedValue ? null : _sourceId,
      amount: amount,
      category: _category.apiValue,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
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