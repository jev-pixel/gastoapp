import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../expenses/domain/expense_model.dart';
import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

const _unallocatedValue = '__unallocated__';

//----------------------------------------------------------------------------
// Design tokens — mirrors the palette used in wallet_screen.dart /
// add_allowance_sheet.dart so this sheet reads as part of the same UI.
//----------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);
  static const iconBg = Color(0xFFFFE3D1);
  static const iconFg = Color(0xFFD9772E);
}

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
  late String _sourceId =
      widget.allowances.isNotEmpty ? widget.allowances.first.id : _unallocatedValue;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _Palette.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Palette.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove_circle_rounded,
                    color: _Palette.iconFg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Spend',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SheetDropdownField<String>(
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
            _SheetTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              label: 'Amount (PHP)',
              icon: Icons.payments_outlined,
              prefixText: '₱ ',
            ),
            const SizedBox(height: 14),
            _SheetDropdownField<ExpenseCategory>(
              value: _category,
              label: 'Category',
              icon: Icons.category_outlined,
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 14),
            _SheetTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _submitting
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_Palette.primaryStart, _Palette.primaryEnd],
                        ),
                  color: _submitting ? _Palette.cardBorder : null,
                  boxShadow: _submitting
                      ? null
                      : [
                          BoxShadow(
                            color: _Palette.primaryStart.withOpacity(0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _submitting ? null : _submit,
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Confirm Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
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

//----------------------------------------------------------------------------
// Shared styled input — matches the card language used across the app.
//----------------------------------------------------------------------------
class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, size: 20, color: _Palette.textMuted),
        labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.primaryStart, width: 1.6),
        ),
      ),
    );
  }
}

class _SheetDropdownField<T> extends StatelessWidget {
  const _SheetDropdownField({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Color(0xFF14231C),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _Palette.textMuted),
        labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.primaryStart, width: 1.6),
        ),
      ),
    );
  }
}
