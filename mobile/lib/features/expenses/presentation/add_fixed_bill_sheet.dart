import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Fixed bills only persist a recurring day-of-month (1-31) on the
  // backend — there's no specific one-time due date stored. We still let
  // the user tap a real calendar to pick it (nicer than typing a number),
  // we just only keep `.day` from whatever date they land on.
  DateTime? _selectedDate;
  bool _submitting = false;

  bool get _isEditing => widget.existingBill != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBill;
    if (existing != null) {
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      // Clamp in case the recurring day doesn't exist in the current month
      // (e.g. a bill due on the 31st, viewed in February).
      final day = existing.dueDay.clamp(1, daysInMonth);
      _selectedDate = DateTime(now.year, now.month, day);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(now.year, now.month + 6, 0),
      helpText: 'Select due date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

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
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: _pickDueDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month_rounded),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Tap to select a date'
                    : DateFormat('MMMM d').format(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null ? Theme.of(context).hintColor : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bills repeat every month on this day — the month you pick here doesn\'t matter, only the day.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
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
    if (_nameController.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in a name, a valid amount, and a due date.')),
      );
      return;
    }
    final dueDay = _selectedDate!.day;

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