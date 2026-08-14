import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/expense_model.dart';
import 'expenses_provider.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.wants;
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
          const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            onPressed: _submitting
                ? null
                : () async {
                    final amount = double.tryParse(_amountController.text);
                    if (amount == null || amount <= 0) return;

                    setState(() => _submitting = true);
                    final success = await context.read<ExpensesProvider>().addExpense(
                          amount: amount,
                          category: _category,
                          description: _descriptionController.text.trim().isEmpty
                              ? null
                              : _descriptionController.text.trim(),
                        );
                    if (!mounted) return;
                    setState(() => _submitting = false);
                    if (success) Navigator.of(context).pop();
                  },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}