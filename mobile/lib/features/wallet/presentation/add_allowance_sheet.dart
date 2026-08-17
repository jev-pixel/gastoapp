import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

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
          Text(_isEditing ? 'Edit Allowance' : 'New Allowance',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: !_isEditing, // renaming isn't supported by the resize endpoint
            decoration: const InputDecoration(labelText: 'Name (e.g. Emergency, Foods)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isEditing ? 'New total allocated amount (PHP)' : 'Amount to allocate (PHP)',
              border: const OutlineInputBorder(),
            ),
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
                : Text(_isEditing ? 'Save Changes' : 'Create Allowance'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : _confirmDelete,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Allowance'),
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
        title: const Text('Delete this allowance?'),
        content: Text(
          'The remaining balance will be returned to your unallocated funds. This does not affect your total wallet balance.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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