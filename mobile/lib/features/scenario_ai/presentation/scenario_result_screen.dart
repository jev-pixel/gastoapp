import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'scenario_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

Color _riskColor(String riskLevel) {
  switch (riskLevel.toUpperCase()) {
    case 'LOW':
      return Colors.green;
    case 'MEDIUM':
      return Colors.orange;
    case 'HIGH':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class ScenarioResultScreen extends StatelessWidget {
  const ScenarioResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<ScenarioProvider>().result;

    if (result == null) {
      return const Scaffold(body: Center(child: Text('No result available.')));
    }

    final riskColor = _riskColor(result.riskLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('Simulation Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Verdict header card
          Card(
            color: riskColor.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_verdictIcon(result.verdict), color: riskColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.verdict,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: riskColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(result.verdictSummary, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial impact card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Financial Impact', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daily Discretionary Budget'),
                      Text(
                        '${_currency.format(result.postExpenseDailyBudget)}/day',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(result.tradeOffAnalysis, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Risk indicator bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(result.riskLevel, style: TextStyle(fontWeight: FontWeight.bold, color: riskColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _riskToFraction(result.riskLevel),
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(riskColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('LOW', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('MEDIUM', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('HIGH', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Compromise options
          if (result.compromiseOptions.isNotEmpty) ...[
            const Text('Compromise Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...result.compromiseOptions.map(
              (option) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(option.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(option.impactDescription),
                  trailing: Text(
                    _currency.format(option.newAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _riskToFraction(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return 0.2;
      case 'MEDIUM':
        return 0.55;
      case 'HIGH':
        return 0.95;
      default:
        return 0.0;
    }
  }

  IconData _verdictIcon(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'PROCEED WITH CAUTION':
        return Icons.warning_amber;
      case 'NOT RECOMMENDED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}