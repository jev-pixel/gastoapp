import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';
import 'wallet_theme.dart';

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
    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: _isEditing ? 'Edit Allowance' : 'New Allowance',
            icon: _isEditing ? Icons.tune_rounded : Icons.pie_chart_rounded,
          ),
          SheetTextField(
            controller: _nameController,
            enabled: !_isEditing,
            label: 'Name (e.g. Emergency, Foods)',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 14),
          SheetTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            label: _isEditing ? 'New total allocated amount (PHP)' : 'Amount to allocate (PHP)',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 24),
          SheetPrimaryButton(
            label: _isEditing ? 'Save Changes' : 'Create Allowance',
            loading: _submitting,
            onTap: _submit,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _submitting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete Allowance'),
              style: TextButton.styleFrom(
                foregroundColor: WalletPalette.danger,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ],
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
          style: TextStyle(color: WalletPalette.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: WalletPalette.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: WalletPalette.danger),
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
