import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

const _unallocatedValue = '__unallocated__';

// ---------------------------------------------------------------------------
// Design tokens — mirrors the palette used in wallet_screen.dart /
// add_allowance_sheet.dart / spend_sheet.dart so this sheet reads as part
// of the same UI, not a bolted-on system dialog.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);
  static const iconBg = Color(0xFFDCEBFF);
  static const iconFg = Color(0xFF2E6ADE);
}

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
                    Icons.swap_horiz_rounded,
                    color: _Palette.iconFg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Transfer',
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
            _SheetDropdownField<String>(
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
            _SheetTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              label: 'Amount (PHP)',
              icon: Icons.payments_outlined,
              prefixText: '₱ ',
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
                              'Confirm Transfer',
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

// ---------------------------------------------------------------------------
// Shared styled inputs — identical to the ones in spend_sheet.dart /
// add_allowance_sheet.dart so all wallet bottom sheets look and feel the
// same. If you already extracted these into a shared widgets file, drop
// these two classes here and import that instead.
// ---------------------------------------------------------------------------
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