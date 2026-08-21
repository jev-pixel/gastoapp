import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Design tokens — same palette as login_screen.dart for a consistent feel.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const surface = Color(0xFFF6F8F5);
  static const fieldFill = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);
}

InputDecoration _fieldDecoration({required String label, IconData? icon, String? prefixText}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, color: _Palette.textMuted, size: 20),
    prefixText: prefixText,
    filled: true,
    fillColor: _Palette.fieldFill,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
  final _passwordController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _savingsFloorController = TextEditingController();
  final _walletBalanceController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _Palette.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            _SectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Personal details',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameController,
              decoration: _fieldDecoration(label: 'Full Name', icon: Icons.badge_outlined),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(label: 'Email', icon: Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _fieldDecoration(label: 'Password', icon: Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _Palette.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Financial Profile',
            ),
            const SizedBox(height: 4),
            const Text(
              'This helps GastoApp tailor budgeting recommendations to you.',
              style: TextStyle(fontSize: 12.5, color: _Palette.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _monthlyIncomeController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                label: 'Monthly Income',
                icon: Icons.payments_outlined,
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _savingsFloorController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                label: 'Target Savings Floor',
                icon: Icons.savings_outlined,
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _walletBalanceController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                label: 'Current Wallet Balance',
                icon: Icons.account_balance_wallet_outlined,
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 18),
            if (auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _Palette.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Palette.danger.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: _Palette.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: _Palette.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final success = await auth.register(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                          fullName: _fullNameController.text.trim(),
                          monthlyIncome: double.tryParse(_monthlyIncomeController.text) ?? 0,
                          targetSavingsFloor: double.tryParse(_savingsFloorController.text) ?? 0,
                          currentWalletBalance:
                              double.tryParse(_walletBalanceController.text) ?? 0,
                        );
                        if (success && mounted) {
                          Navigator.of(context).pushReplacementNamed('/dashboard');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.primaryStart,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
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
            color: const Color(0xFFE3F5DE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _Palette.primaryStart),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
        ),
      ],
    );
  }
}