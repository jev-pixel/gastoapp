import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class WalletSimulatorScreen extends StatefulWidget {
  const WalletSimulatorScreen({super.key});

  @override
  State<WalletSimulatorScreen> createState() => _WalletSimulatorScreenState();
}

class _WalletSimulatorScreenState extends State<WalletSimulatorScreen> {
  final _goalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final result = wallet.lastSimulation;

    return Scaffold(
      appBar: AppBar(title: const Text('Unallocated Funds Advisor')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Got leftover money after budgeting? Tell the AI what you're thinking, or leave it blank for a general recommendation.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'What are you considering? (optional)',
                hintText: 'e.g. "buy a new phone" or leave blank',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: wallet.isSimulating
                  ? null
                  : () => context.read<WalletProvider>().simulateUnallocated(
                        goalDescription: _goalController.text.trim().isEmpty
                            ? null
                            : _goalController.text.trim(),
                      ),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: wallet.isSimulating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Get Recommendation'),
            ),
            if (wallet.errorMessage != null && result == null) ...[
              const SizedBox(height: 12),
              Text(wallet.errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            if (result != null) ...[
              const SizedBox(height: 24),
              _ResultCard(result: result),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final UnallocatedSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unallocated: ${_currency.format(result.unallocatedBalance)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Text(result.recommendationSummary, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(child: Text(result.riskNote, style: const TextStyle(fontSize: 13))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Suggested Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...result.suggestedActions.map(
          (action) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(action.action, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(action.reasoning),
              trailing: Text(
                _currency.format(action.suggestedAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}