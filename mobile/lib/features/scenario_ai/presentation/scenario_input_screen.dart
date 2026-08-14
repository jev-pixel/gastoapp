import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'scenario_provider.dart';
import 'scenario_result_screen.dart';

class ScenarioInputScreen extends StatefulWidget {
  const ScenarioInputScreen({super.key});

  @override
  State<ScenarioInputScreen> createState() => _ScenarioInputScreenState();
}

class _ScenarioInputScreenState extends State<ScenarioInputScreen> {
  final _amountController = TextEditingController();
  final _essentialAllowanceController = TextEditingController(text: '4000');
  String _category = 'Wants/Entertainment';

  static const _categories = [
    'Wants/Entertainment',
    'Food & Dining',
    'Shopping',
    'Travel',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final scenario = context.watch<ScenarioProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('What-If Simulator')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Thinking of buying something? Check the impact before you spend.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount (PHP)',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _essentialAllowanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Remaining Essentials Budget (PHP)',
                helperText: 'Food/transport money you still need this cycle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (scenario.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(scenario.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: scenario.isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(_amountController.text);
                      if (amount == null || amount <= 0) return;

                      await scenario.simulate(
                        proposedAmount: amount,
                        category: _category,
                        essentialAllowanceRemaining:
                            double.tryParse(_essentialAllowanceController.text) ?? 0,
                      );

                      if (scenario.result != null && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScenarioResultScreen()),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: scenario.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Check My Buffer'),
            ),
          ],
        ),
      ),
    );
  }
}