import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

/// Formats a numeric text field with thousands separators as the user types,
/// e.g. "12000" -> "12,000". Keeps the stored value digit-only for parsing.
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      final posFromEnd = digitsOnly.length - i;
      buffer.write(digitsOnly[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _incomeController;
  late final TextEditingController _savingsFloorController;
  late final TextEditingController _walletBalanceController;

  bool _initialized = false;
  bool _submitting = false;
  String? _lastShownError;

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _incomeController.dispose();
      _savingsFloorController.dispose();
      _walletBalanceController.dispose();
    }
    super.dispose();
  }

  double? _parseAmount(String text) {
    final digitsOnly = text.replaceAll(',', '');
    if (digitsOnly.isEmpty) return null;
    return double.tryParse(digitsOnly);
  }

  String _formatAmount(double value) {
    return _ThousandsSeparatorInputFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: value.toStringAsFixed(0)),
        )
        .text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (!_initialized && user != null) {
      _nameController = TextEditingController(text: user.fullName);
      _incomeController =
          TextEditingController(text: _formatAmount(user.monthlyIncome));
      _savingsFloorController =
          TextEditingController(text: _formatAmount(user.targetSavingsFloor));
      _walletBalanceController = TextEditingController(
          text: _formatAmount(user.currentWalletBalance));
      _initialized = true;
    }

    if (user == null || !_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Surface backend errors as a snackbar rather than a static, easy-to-miss
    // line of red text, and only once per new error.
    if (auth.errorMessage != null && auth.errorMessage != _lastShownError) {
      _lastShownError = auth.errorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
      });
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // --- Avatar + name preview -------------------------------
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _initials(_nameController.text.isEmpty
                            ? user.fullName
                            : _nameController.text),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Update your personal and financial details',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SectionCard(
                title: 'Personal information',
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(
                      label: 'Full name',
                      icon: Icons.badge_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                title: 'Financial details',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  TextFormField(
                    controller: _incomeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                    decoration: _fieldDecoration(
                      label: 'Monthly income',
                      icon: Icons.payments_outlined,
                      prefixText: '₱ ',
                    ),
                    validator: (value) =>
                        _validateAmount(value, fieldName: 'monthly income'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _savingsFloorController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                    decoration: _fieldDecoration(
                      label: 'Target savings floor',
                      icon: Icons.savings_outlined,
                      prefixText: '₱ ',
                      helperText:
                          'The minimum balance you want to always keep',
                    ),
                    validator: (value) => _validateAmount(value,
                        fieldName: 'target savings floor'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _walletBalanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                    decoration: _fieldDecoration(
                      label: 'Current wallet balance',
                      icon: Icons.account_balance_wallet_outlined,
                      prefixText: '₱ ',
                    ),
                    validator: (value) => _validateAmount(value,
                        fieldName: 'current wallet balance'),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_submitting ? 'Saving…' : 'Save changes'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? prefixText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      prefixText: prefixText,
      helperText: helperText,
      helperMaxLines: 2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    );
  }

  String? _validateAmount(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    final parsed = _parseAmount(value);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final income = _parseAmount(_incomeController.text)!;
    final savingsFloor = _parseAmount(_savingsFloorController.text)!;
    final walletBalance = _parseAmount(_walletBalanceController.text)!;

    setState(() => _submitting = true);
    final success = await context.read<AuthProvider>().updateProfile(
          fullName: name,
          monthlyIncome: income,
          targetSavingsFloor: savingsFloor,
          currentWalletBalance: walletBalance,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.of(context).pop();
    }
  }
}

/// A titled card wrapper used to visually group related form fields.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}