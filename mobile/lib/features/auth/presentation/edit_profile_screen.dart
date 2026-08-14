import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _incomeController;
  late final TextEditingController _savingsFloorController;
  late final TextEditingController _walletBalanceController;
  bool _initialized = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (!_initialized && user != null) {
      _nameController = TextEditingController(text: user.fullName);
      _incomeController = TextEditingController(text: user.monthlyIncome.toStringAsFixed(0));
      _savingsFloorController = TextEditingController(text: user.targetSavingsFloor.toStringAsFixed(0));
      _walletBalanceController = TextEditingController(text: user.currentWalletBalance.toStringAsFixed(0));
      _initialized = true;
    }

    if (user == null || !_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeController,
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
            const SizedBox(height: 8),
            if (auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final income = double.tryParse(_incomeController.text);
    final savingsFloor = double.tryParse(_savingsFloorController.text);
    final walletBalance = double.tryParse(_walletBalanceController.text);

    if (name.isEmpty || income == null || savingsFloor == null || walletBalance == null) return;

    setState(() => _submitting = true);
    final success = await context.read<AuthProvider>().updateProfile(
          fullName: name,
          monthlyIncome: income,
          targetSavingsFloor: savingsFloor,
          currentWalletBalance: walletBalance,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.of(context).pop();
  }
}