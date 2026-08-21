import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../expenses/domain/expense_model.dart';
import '../../expenses/presentation/expenses_provider.dart';
import '../../wallet/domain/wallet_model.dart';
import '../../wallet/presentation/wallet_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

// ---------------------------------------------------------------------------
// Design tokens — mirrors the palette used in wallet_screen.dart so both
// screens read as one app. Kept local so this file stays drop-in without
// touching your app-wide theme.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);

  static const statIconBg = [
    Color(0xFFFFE3D1), // orange (unpaid dues)
    Color(0xFFDCEBFF), // blue (allocated)
  ];
  static const statIconFg = [
    Color(0xFFD9772E),
    Color(0xFF2E6ADE),
  ];
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
      // Wallet summary is the single source of truth for balance figures
      // shown on this screen (see _BalanceCard) — load it alongside the
      // ledger data rather than relying on the cached AuthProvider user,
      // which is never refreshed after wallet actions (spend/transfer/
      // allowance changes) and would otherwise go stale here.
      context.read<WalletProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpensesProvider>();
    final wallet = context.watch<WalletProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _Palette.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
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
              foregroundColor: _Palette.primaryStart,
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
              onRefresh: () => Future.wait([
                context.read<ExpensesProvider>().loadAll(),
                context.read<WalletProvider>().loadSummary(),
              ]),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Hi, ${user.fullName.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BalanceCard(summary: wallet.summary, totalUnpaidDues: expenses.totalUnpaidFixedDues),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Unpaid Fixed Dues',
                          value: _currency.format(expenses.totalUnpaidFixedDues),
                          icon: Icons.receipt_long_rounded,
                          colorIndex: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Allocated in Allowances',
                          value: wallet.summary != null
                              ? _currency.format(wallet.summary!.allocatedTotal)
                              : '—',
                          icon: Icons.pie_chart_rounded,
                          colorIndex: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Expenses',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/expenses'),
                        style: TextButton.styleFrom(
                          foregroundColor: _Palette.primaryStart,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (expenses.expenses.isEmpty)
                    _EmptyExpensesState()
                  else
                    _RecentExpensesList(expenses: expenses.expenses.take(5).toList()),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/scenario'),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: const Text('Simulate a Purchase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primaryStart,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
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
  final WalletSummary? summary;
  final double totalUnpaidDues;

  const _BalanceCard({required this.summary, required this.totalUnpaidDues});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _Palette.cardBorder),
        ),
        padding: const EdgeInsets.all(32),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Merged formula: disposable is what's left in the Unallocated bucket
    // once still-unpaid fixed bills are set aside. Allocated allowances are
    // already excluded from "unallocated" by the backend's own summary
    // calculation, so we don't subtract a separate savings-floor figure
    // here anymore — create a "Savings" allowance if you want that
    // reserved explicitly.
    final disposable = summary!.unallocatedBalance - totalUnpaidDues;

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
              _currency.format(summary!.currentWalletBalance),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.16)),
            const SizedBox(height: 16),
            Text(
              'Roughly ${_currency.format(disposable)} disposable — ${_currency.format(summary!.unallocatedBalance)} unallocated minus unpaid dues',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
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
  final int colorIndex;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _Palette.statIconBg[colorIndex % _Palette.statIconBg.length];
    final fg = _Palette.statIconFg[colorIndex % _Palette.statIconFg.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _Palette.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpensesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F5DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: _Palette.primaryStart, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'No expenses yet.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _Palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RecentExpensesList extends StatelessWidget {
  final List<Expense> expenses;

  const _RecentExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < expenses.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: _Palette.cardBorder),
            ListTile(
              title: Text(
                expenses[i].description?.isNotEmpty == true
                    ? expenses[i].description!
                    : expenses[i].category.label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                DateFormat.yMMMd().format(expenses[i].occurredAt),
                style: const TextStyle(color: _Palette.textMuted, fontSize: 12),
              ),
              trailing: Text(
                _currency.format(expenses[i].amount),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}