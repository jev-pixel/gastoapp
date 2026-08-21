import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

// ---------------------------------------------------------------------------
// Design tokens — mirrors the palette used in wallet_screen.dart so this
// sheet reads as part of the same UI, not a bolted-on system dialog.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);
  static const iconBg = Color(0xFFE3F5DE);
}

class AddAllowanceSheet extends StatefulWidget {
  final Allowance? existingAllowance;
  const AddAllowanceSheet({super.key, this.existingAllowance});

  @override
  State<AddAllowanceSheet> createState() => _AddAllowanceSheetState();
}

class _AddAllowanceSheetState extends State<AddAllowanceSheet> {
  late final _nameController = TextEditingController(text: widget.existingAllowance?.name ?? '');
  late final _amountController = TextEditingController(
    text: widget.existingAllowance?.allocatedAmount.toStringAsFixed(0) ?? '',
  );
  bool _submitting = false;

  bool get _isEditing => widget.existingAllowance != null;

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
                  child: Icon(
                    _isEditing ? Icons.tune_rounded : Icons.pie_chart_rounded,
                    color: _Palette.primaryStart,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Edit Allowance' : 'New Allowance',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SheetTextField(
              controller: _nameController,
              enabled: !_isEditing,
              label: 'Name (e.g. Emergency, Foods)',
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 14),
            _SheetTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              label: _isEditing ? 'New total allocated amount (PHP)' : 'Amount to allocate (PHP)',
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
                          : Text(
                              _isEditing ? 'Save Changes' : 'Create Allowance',
                              style: const TextStyle(
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
            if (_isEditing) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _submitting ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Allowance'),
                style: TextButton.styleFrom(
                  foregroundColor: _Palette.danger,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    if (!_isEditing && _nameController.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    final provider = context.read<WalletProvider>();
    final success = _isEditing
        ? await provider.resizeAllowance(id: widget.existingAllowance!.id, allocatedAmount: amount)
        : await provider.createAllowance(name: _nameController.text.trim(), allocatedAmount: amount);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete this allowance?',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        content: const Text(
          'The remaining balance will be returned to your unallocated funds. This does not affect your total wallet balance.',
          style: TextStyle(color: _Palette.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: _Palette.danger),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    final success = await context.read<WalletProvider>().deleteAllowance(widget.existingAllowance!.id);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Shared input styling — rounded, tinted, matches the card language used
// throughout wallet_screen.dart.
// ---------------------------------------------------------------------------
class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.keyboardType,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, size: 20, color: _Palette.textMuted),
        labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: enabled ? Colors.white : _Palette.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Palette.cardBorder),
        ),
        disabledBorder: OutlineInputBorder(
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