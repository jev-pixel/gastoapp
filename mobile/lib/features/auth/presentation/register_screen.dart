import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Financial Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _monthlyIncomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Income (PHP)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _savingsFloorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Savings Floor (PHP)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _walletBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current Wallet Balance (PHP)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            if (auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final success = await auth.register(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        fullName: _fullNameController.text.trim(),
                        monthlyIncome: double.tryParse(_monthlyIncomeController.text) ?? 0,
                        targetSavingsFloor: double.tryParse(_savingsFloorController.text) ?? 0,
                        currentWalletBalance: double.tryParse(_walletBalanceController.text) ?? 0,
                      );
                      if (success && mounted) {
                        Navigator.of(context).pushReplacementNamed('/dashboard');
                      }
                    },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}