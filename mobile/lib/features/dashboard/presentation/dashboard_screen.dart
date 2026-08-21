import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../expenses/domain/expense_model.dart';
import '../../expenses/presentation/expenses_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

// ---------------------------------------------------------------------------
// Design tokens — same palette as login/register/wallet screens.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const accentBlueStart = Color(0xFF2E6ADE);
  static const accentBlueEnd = Color(0xFF5B9BF0);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const orange = Color(0xFFD9772E);
  static const orangeBg = Color(0xFFFFE3D1);
  static const blue = Color(0xFF2E6ADE);
  static const blueBg = Color(0xFFDCEBFF);
}

IconData _iconForCategory(String label) {
  final n = label.toLowerCase();
  if (n.contains('food') || n.contains('grocer') || n.contains('dining')) {
    return Icons.restaurant_rounded;
  }
  if (n.contains('electric') || n.contains('power') || n.contains('utili')) {
    return Icons.bolt_rounded;
  }
  if (n.contains('water')) return Icons.water_drop_rounded;
  if (n.contains('rent') || n.contains('house') || n.contains('home')) {
    return Icons.home_rounded;
  }
  if (n.contains('transport') || n.contains('gas') || n.contains('fuel')) {
    return Icons.directions_car_filled_rounded;
  }
  if (n.contains('save') || n.contains('emergency')) return Icons.savings_rounded;
  if (n.contains('school') || n.contains('tuition') || n.contains('educat')) {
    return Icons.school_rounded;
  }
  if (n.contains('health') || n.contains('medic')) return Icons.local_hospital_rounded;
  if (n.contains('internet') || n.contains('wifi') || n.contains('data')) {
    return Icons.wifi_rounded;
  }
  if (n.contains('shop') || n.contains('cloth')) return Icons.shopping_bag_rounded;
  return Icons.receipt_long_rounded;
}

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
      backgroundColor: _Palette.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'GastoApp',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _Palette.primaryStart,
            ),
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _Palette.textMuted,
            ),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<ExpensesProvider>().loadAll(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Hi, ${user.fullName.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Here\'s where your money stands today.',
                    style: TextStyle(fontSize: 13.5, color: _Palette.textMuted),
                  ),
                  const SizedBox(height: 18),
                  _BalanceCard(user: user, totalUnpaidDues: expenses.totalUnpaidFixedDues),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Unpaid Fixed Dues',
                          value: _currency.format(expenses.totalUnpaidFixedDues),
                          icon: Icons.receipt_long_rounded,
                          iconColor: _Palette.orange,
                          iconBg: _Palette.orangeBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Savings Floor',
                          value: _currency.format(user.targetSavingsFloor),
                          icon: Icons.savings_rounded,
                          iconColor: _Palette.blue,
                          iconBg: _Palette.blueBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/expenses'),
                        style: TextButton.styleFrom(foregroundColor: _Palette.primaryStart),
                        child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (expenses.expenses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Palette.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: _Palette.textMuted, size: 28),
                          SizedBox(height: 8),
                          Text('No expenses yet.', style: TextStyle(color: _Palette.textMuted)),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Palette.cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          for (final e in expenses.expenses.take(5)) _ExpenseTile(expense: e),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_Palette.accentBlueStart, _Palette.accentBlueEnd],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _Palette.accentBlueStart.withOpacity(0.24),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/scenario'),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Simulate a Purchase'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/expenses'),
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      label: const Text('Manage Ledger'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Palette.primaryStart,
                        side: const BorderSide(color: _Palette.primaryStart, width: 1.4),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/wallet'),
                      icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      label: const Text('Manage Allowances'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Palette.primaryStart,
                        side: const BorderSide(color: _Palette.primaryStart, width: 1.4),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.primaryStart, _Palette.primaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.primaryStart.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT WALLET BALANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _currency.format(user.currentWalletBalance),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.16)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      children: [
                        const TextSpan(text: 'Roughly '),
                        TextSpan(
                          text: _currency.format(disposable),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const TextSpan(text: ' disposable after unpaid dues and savings floor'),
                      ],
                    ),
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: _Palette.textMuted)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final label = expense.description?.isNotEmpty == true
        ? expense.description!
        : expense.category.label;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F5DE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _iconForCategory(expense.category.label),
          size: 18,
          color: _Palette.primaryStart,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat.yMMMd().format(expense.occurredAt),
        style: const TextStyle(fontSize: 12, color: _Palette.textMuted),
      ),
      trailing: Text(
        _currency.format(expense.amount),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}