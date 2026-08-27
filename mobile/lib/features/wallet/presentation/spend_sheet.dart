import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../expenses/domain/expense_model.dart';
import '../domain/wallet_model.dart';
import 'wallet_provider.dart';
import 'wallet_theme.dart';

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
  DateTime? _dueDate;
  late String _sourceId =
      widget.allowances.isNotEmpty ? widget.allowances.first.id : _unallocatedValue;
  bool _submitting = false;

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: 'Select due date',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(
            title: 'Spend',
            icon: Icons.remove_circle_rounded,
            iconBg: Color(0xFFFFE3D1),
            iconFg: Color(0xFFD9772E),
          ),
          SheetDropdownField<String>(
            value: _sourceId,
            label: 'Pay from',
            icon: Icons.account_balance_wallet_outlined,
            items: [
              ...widget.allowances.map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} (₱${a.currentBalance.toStringAsFixed(0)} left)'),
                ),
              ),
              const DropdownMenuItem(
                value: _unallocatedValue,
                child: Text('Unallocated funds'),
              ),
            ],
            onChanged: (value) => setState(() => _sourceId = value!),
          ),
          const SizedBox(height: 14),
          SheetTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            label: 'Amount (PHP)',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 14),
          SheetDropdownField<ExpenseCategory>(
            value: _category,
            label: 'Category',
            icon: Icons.category_outlined,
            items: ExpenseCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (value) => setState(() {
              _category = value!;
              // Clear a previously-picked date if the user switches away
              // from Fixed Due, so a stale date can't get silently reused.
              if (_category != ExpenseCategory.fixedDue) _dueDate = null;
            }),
          ),
          if (_category == ExpenseCategory.fixedDue) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due date',
                  prefixIcon: const Icon(Icons.event_outlined, size: 20, color: WalletPalette.textMuted),
                  labelStyle: const TextStyle(color: WalletPalette.textMuted, fontSize: 13.5),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: WalletPalette.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: WalletPalette.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: WalletPalette.primaryEnd, width: 1.6),
                  ),
                ),
                child: Text(
                  _dueDate == null ? 'Tap to select a date' : DateFormat.yMMMd().format(_dueDate!),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _dueDate == null ? Theme.of(context).hintColor : WalletPalette.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "This will be reserved but your balance won't be deducted until you mark it as paid.",
              style: TextStyle(fontSize: 12, color: WalletPalette.textMuted, height: 1.3),
            ),
          ],
          const SizedBox(height: 14),
          SheetTextField(
            controller: _descriptionController,
            label: 'Description (optional)',
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 24),
          SheetPrimaryButton(
            label: _category == ExpenseCategory.fixedDue ? 'Reserve Fixed Due' : 'Confirm Expense',
            loading: _submitting,
            colors: const [Color(0xFFD9772E), Color(0xFFF0AE3F)],
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    if (_category == ExpenseCategory.fixedDue && _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date for this Fixed Due.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<WalletProvider>();
    final success = await provider.spend(
      allowanceId: _sourceId == _unallocatedValue ? null : _sourceId,
      amount: amount,
      category: _category.apiValue,
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      dueDate: _category == ExpenseCategory.fixedDue ? _dueDate : null,
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
