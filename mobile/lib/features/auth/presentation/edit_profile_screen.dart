import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'glass_theme.dart';

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
      return const Scaffold(
        backgroundColor: LightGlassTheme.canvasBackground,
        body: Center(child: CircularProgressIndicator(color: LightGlassTheme.forestGreen)),
      );
    }

    if (auth.errorMessage != null && auth.errorMessage != _lastShownError) {
      _lastShownError = auth.errorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage!),
              backgroundColor: LightGlassTheme.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
      });
    }

    return Scaffold(
      backgroundColor: LightGlassTheme.canvasBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LightGlassTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: LightGlassTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: GlowBlob(
              colors: [LightGlassTheme.brightGold, LightGlassTheme.darkGold],
              size: 320,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: GlowBlob(
              colors: [LightGlassTheme.lighterGreen, LightGlassTheme.forestGreen],
              size: 360,
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      LightGlassCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [LightGlassTheme.brightGold, LightGlassTheme.darkGold],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: LightGlassTheme.forestGreen,
                                child: Text(
                                  _initials(_nameController.text.isEmpty
                                      ? user.fullName
                                      : _nameController.text),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Personal & Financial Details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: LightGlassTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Update your information synced across your devices',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: LightGlassTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      LightGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionHeader(
                              icon: Icons.person_outline_rounded,
                              title: 'Personal information',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: LightGlassTheme.textPrimary, fontWeight: FontWeight.w600),
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
                      ),
                      const SizedBox(height: 18),

                      LightGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionHeader(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Financial details',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _incomeController,
                              style: const TextStyle(color: LightGlassTheme.textPrimary, fontWeight: FontWeight.w600),
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
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _savingsFloorController,
                              style: const TextStyle(color: LightGlassTheme.textPrimary, fontWeight: FontWeight.w600),
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
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _walletBalanceController,
                              style: const TextStyle(color: LightGlassTheme.textPrimary, fontWeight: FontWeight.w600),
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
                      ),

                      const SizedBox(height: 28),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [LightGlassTheme.forestGreen, LightGlassTheme.lighterGreen],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: LightGlassTheme.forestGreen.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                              : const Icon(Icons.check_circle_outline_rounded, color: LightGlassTheme.brightGold),
                          label: Text(
                            _submitting ? 'Saving…' : 'Save changes',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: LightGlassTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
      labelStyle: const TextStyle(color: LightGlassTheme.textMuted, fontSize: 13.5),
      prefixIcon: Icon(icon, color: LightGlassTheme.forestGreen, size: 20),
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: LightGlassTheme.forestGreen, fontWeight: FontWeight.bold),
      helperText: helperText,
      helperStyle: const TextStyle(color: LightGlassTheme.textMuted),
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.white.withOpacity(0.75),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LightGlassTheme.subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LightGlassTheme.forestGreen, width: 1.6),
      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: LightGlassTheme.forestGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: LightGlassTheme.forestGreen),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: LightGlassTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}