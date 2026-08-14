import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/fixed_bill_model.dart';
import 'expenses_provider.dart';

class AddFixedBillSheet extends StatefulWidget {
  final FixedBill? existingBill;
  const AddFixedBillSheet({super.key, this.existingBill});

  @override
  State<AddFixedBillSheet> createState() => _AddFixedBillSheetState();
}

class _AddFixedBillSheetState extends State<AddFixedBillSheet> {
  late final _nameController = TextEditingController(text: widget.existingBill?.name ?? '');
  late final _amountController =
      TextEditingController(text: widget.existingBill?.amount.toStringAsFixed(0) ?? '');
  late final _dueDayController =
      TextEditingController(text: widget.existingBill?.dueDay.toString() ?? '');
  bool _submitting = false;

  bool get _isEditing => widget.existingBill != null;

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
          Text(_isEditing ? 'Edit Fixed Bill' : 'Add Fixed Bill',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name (e.g. Rent, Electricity)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (PHP)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dueDayController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Due Day (1-31)', border: OutlineInputBorder()),
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
                : Text(_isEditing ? 'Save Changes' : 'Add Fixed Bill'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    final dueDay = int.tryParse(_dueDayController.text);
    if (_nameController.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        dueDay == null ||
        dueDay < 1 ||
        dueDay > 31) {
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<ExpensesProvider>();
    final success = _isEditing
        ? await provider.updateFixedBill(
            id: widget.existingBill!.id,
            name: _nameController.text.trim(),
            amount: amount,
            dueDay: dueDay,
          )
        : await provider.addFixedBill(
            name: _nameController.text.trim(),
            amount: amount,
            dueDay: dueDay,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.of(context).pop();
  }
}