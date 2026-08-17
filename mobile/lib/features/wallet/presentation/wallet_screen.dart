import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'add_allowance_sheet.dart';
import 'spend_sheet.dart';
import 'transfer_sheet.dart';
import 'wallet_history_screen.dart';
import 'wallet_provider.dart';
import 'wallet_simulator_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final summary = wallet.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Allowances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transaction history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
            ),
          ),
        ],
      ),
      body: wallet.isLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      wallet.errorMessage ?? 'Could not load wallet summary.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<WalletProvider>().loadSummary(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCard(summary: summary),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Allowances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const AddAllowanceSheet(),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (summary.allowances.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No allowances yet. Tap "New" to split your wallet into budget envelopes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: summary.allowances.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, index) =>
                              _AllowanceCard(allowance: summary.allowances[index]),
                        ),
                      const SizedBox(height: 24),
                      if (summary.unallocatedBalance > 0)
                        Card(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have ${_currency.format(summary.unallocatedBalance)} unallocated. Get a recommendation on what to do with it.',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const WalletSimulatorScreen()),
                                  ),
                                  child: const Text('Ask AI'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => SpendSheet(allowances: summary.allowances),
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Spend'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: summary.allowances.isEmpty
                                  ? null
                                  : () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => TransferSheet(allowances: summary.allowances),
                                      ),
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Transfer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Wallet Balance', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _currency.format(summary.currentWalletBalance),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(label: 'Allocated', value: _currency.format(summary.allocatedTotal)),
                _MiniStat(
                  label: 'Unallocated',
                  value: _currency.format(summary.unallocatedBalance),
                  emphasize: summary.unallocatedBalance > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: emphasize ? Theme.of(context).colorScheme.tertiary : null,
          ),
        ),
      ],
    );
  }
}

class _AllowanceCard extends StatelessWidget {
  const _AllowanceCard({required this.allowance});
  final Allowance allowance;

  @override
  Widget build(BuildContext context) {
    final fraction = allowance.allocatedAmount == 0
        ? 0.0
        : (allowance.currentBalance / allowance.allocatedAmount).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddAllowanceSheet(existingAllowance: allowance),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                allowance.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currency.format(allowance.currentBalance),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'of ${_currency.format(allowance.allocatedAmount)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}