import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'glass_theme.dart';
import 'pin_input_field.dart';

const String _emailDomain = '@gasto.ph';

InputDecoration _registerFieldDecoration({required String label, IconData? icon, String? prefixText}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: LightGlassTheme.textMuted, fontSize: 13.5),
    prefixIcon: icon == null ? null : Icon(icon, color: LightGlassTheme.forestGreen, size: 20),
    prefixText: prefixText,
    prefixStyle: const TextStyle(color: LightGlassTheme.forestGreen, fontWeight: FontWeight.bold),
    filled: true,
    fillColor: Colors.white.withOpacity(0.75),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: LightGlassTheme.subtleBorder),
    ),
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _savingsFloorController = TextEditingController();
  final _walletBalanceController = TextEditingController();

  final _pinKey = GlobalKey<PinInputFieldState>();
  final _confirmPinKey = GlobalKey<PinInputFieldState>();
  String _pin = '';
  String _confirmPin = '';
  bool _obscurePin = true;
  String? _pinValidationError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _monthlyIncomeController.dispose();
    _savingsFloorController.dispose();
    _walletBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_pin.length != 4 || _confirmPin.length != 4) {
      setState(() => _pinValidationError = 'Enter your 4-digit PIN twice to confirm it.');
      HapticFeedback.mediumImpact();
      return;
    }
    if (_pin != _confirmPin) {
      setState(() => _pinValidationError = "PINs don't match — try entering them again.");
      HapticFeedback.mediumImpact();
      _confirmPinKey.currentState?.clear();
      return;
    }
    setState(() => _pinValidationError = null);

    final success = await auth.register(
      email: '${_emailController.text.trim()}$_emailDomain',
      pin: _pin,
      fullName: _fullNameController.text.trim(),
      monthlyIncome: double.tryParse(_monthlyIncomeController.text) ?? 0,
      targetSavingsFloor: double.tryParse(_savingsFloorController.text) ?? 0,
      currentWalletBalance: double.tryParse(_walletBalanceController.text) ?? 0,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: LightGlassTheme.canvasBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LightGlassTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Account',
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
            left: -60,
            child: GlowBlob(
              colors: [LightGlassTheme.brightGold, LightGlassTheme.darkGold],
              size: 320,
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: GlowBlob(
              colors: [LightGlassTheme.lighterGreen, LightGlassTheme.forestGreen],
              size: 360,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    LightGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.person_outline_rounded,
                            title: 'Personal Details',
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _fullNameController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: _registerFieldDecoration(label: 'Full Name', icon: Icons.badge_outlined),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'[@\s]')),
                            ],
                            decoration: _registerFieldDecoration(
                              label: 'Username',
                              icon: Icons.mail_outline_rounded,
                            ).copyWith(
                              suffixText: _emailDomain,
                              suffixStyle: const TextStyle(
                                color: LightGlassTheme.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Set a 4-Digit PIN',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: LightGlassTheme.textPrimary),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _obscurePin = !_obscurePin),
                                child: Icon(
                                  _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: LightGlassTheme.textMuted,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "You'll use this PIN to log in — no need to remember a full password.",
                            style: TextStyle(fontSize: 12.5, color: LightGlassTheme.textMuted, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          PinInputField(
                            key: _pinKey,
                            obscure: _obscurePin,
                            hasError: _pinValidationError != null,
                            onChanged: (value) => setState(() {
                              _pin = value;
                              _pinValidationError = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Confirm PIN',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LightGlassTheme.textMuted),
                          ),
                          const SizedBox(height: 10),
                          PinInputField(
                            key: _confirmPinKey,
                            obscure: _obscurePin,
                            hasError: _pinValidationError != null,
                            onChanged: (value) => setState(() {
                              _confirmPin = value;
                              _pinValidationError = null;
                            }),
                          ),
                          if (_pinValidationError != null) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                _pinValidationError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: LightGlassTheme.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    LightGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.pie_chart_outline_rounded,
                            title: 'Financial Profile',
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This helps GastoApp tailor budgeting recommendations to you.',
                            style: TextStyle(fontSize: 12.5, color: LightGlassTheme.textMuted, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _monthlyIncomeController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            keyboardType: TextInputType.number,
                            decoration: _registerFieldDecoration(
                              label: 'Monthly Income',
                              icon: Icons.payments_outlined,
                              prefixText: '₱ ',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _savingsFloorController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            keyboardType: TextInputType.number,
                            decoration: _registerFieldDecoration(
                              label: 'Target Savings Floor',
                              icon: Icons.savings_outlined,
                              prefixText: '₱ ',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _walletBalanceController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            keyboardType: TextInputType.number,
                            decoration: _registerFieldDecoration(
                              label: 'Current Wallet Balance',
                              icon: Icons.account_balance_wallet_outlined,
                              prefixText: '₱ ',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: LightGlassTheme.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: LightGlassTheme.danger.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: LightGlassTheme.danger, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(color: LightGlassTheme.danger, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : () => _submit(auth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: LightGlassTheme.textPrimary),
        ),
      ],
    );
  }
}