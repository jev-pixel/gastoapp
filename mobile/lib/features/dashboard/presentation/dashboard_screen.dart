import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../expenses/domain/expense_model.dart';
import '../../expenses/presentation/expenses_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpensesProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GastoApp'),
actions: [
  IconButton(
    icon: const Icon(Icons.edit),
    onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
  ),
  IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      await auth.logout();
      if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
    },
  ),
],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<ExpensesProvider>().loadAll(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Hi, ${user.fullName.split(' ').first}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _BalanceCard(user: user, totalUnpaidDues: expenses.totalUnpaidFixedDues),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Unpaid Fixed Dues',
                          value: _currency.format(expenses.totalUnpaidFixedDues),
                          icon: Icons.receipt_long,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Savings Floor',
                          value: _currency.format(user.targetSavingsFloor),
                          icon: Icons.savings,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/expenses'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  if (expenses.expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No expenses yet.', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...expenses.expenses.take(5).map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.description?.isNotEmpty == true ? e.description! : e.category.label),
                            subtitle: Text(DateFormat.yMMMd().format(e.occurredAt)),
                            trailing: Text(_currency.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/scenario'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Simulate a Purchase'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/expenses'),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Manage Ledger'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final dynamic user;
  final double totalUnpaidDues;

  const _BalanceCard({required this.user, required this.totalUnpaidDues});

  @override
  Widget build(BuildContext context) {
    final disposable = user.currentWalletBalance - totalUnpaidDues - user.targetSavingsFloor;

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
              _currency.format(user.currentWalletBalance),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Roughly ${_currency.format(disposable)} disposable after unpaid dues and savings floor',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}