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

// ---------------------------------------------------------------------------
// Design tokens — kept local so the file stays drop-in without touching
// your app-wide theme. Feel free to move these into ThemeData later.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const accentBlueStart = Color(0xFF2E6ADE);
  static const accentBlueEnd = Color(0xFF5B9BF0);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);

  static const allowanceIconBg = [
    Color(0xFFFFE3D1),
    Color(0xFFDCEBFF),
    Color(0xFFE3F5DE),
    Color(0xFFFCE3F1),
    Color(0xFFFFF3C4),
    Color(0xFFE4E1FF),
  ];
  static const allowanceIconFg = [
    Color(0xFFD9772E),
    Color(0xFF2E6ADE),
    Color(0xFF2E9E5B),
    Color(0xFFC1428A),
    Color(0xFFC79A1E),
    Color(0xFF6C5CE7),
  ];
}

IconData _iconForAllowance(String name) {
  final n = name.toLowerCase();
  if (n.contains('food') || n.contains('grocer')) return Icons.restaurant_rounded;
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
  return Icons.account_balance_wallet_rounded;
}

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
      backgroundColor: _Palette.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          'Wallet Allowances',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Transaction history',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B7A4A),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: wallet.isLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 40, color: _Palette.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          wallet.errorMessage ?? 'Could not load wallet summary.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _Palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<WalletProvider>().loadSummary(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _SummaryCard(summary: summary),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Allowances',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          _NewAllowanceButton(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const AddAllowanceSheet(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (summary.allowances.isEmpty)
                        _EmptyAllowancesState(
                          onCreate: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const AddAllowanceSheet(),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: summary.allowances.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.35,
                          ),
                          itemBuilder: (context, index) => _AllowanceCard(
                            allowance: summary.allowances[index],
                            colorIndex: index,
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (summary.unallocatedBalance > 0)
                        _UnallocatedBanner(
                          amount: summary.unallocatedBalance,
                          onAskAi: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const WalletSimulatorScreen()),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryActionButton(
                              icon: Icons.remove_circle_rounded,
                              label: 'Spend',
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    SpendSheet(allowances: summary.allowances),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SecondaryActionButton(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Transfer',
                              onPressed: summary.allowances.isEmpty
                                  ? null
                                  : () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => TransferSheet(
                                            allowances: summary.allowances),
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

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
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
              _currency.format(summary.currentWalletBalance),
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
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Allocated',
                    value: _currency.format(summary.allocatedTotal),
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withOpacity(0.16),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Unallocated',
                    value: _currency.format(summary.unallocatedBalance),
                    emphasize: summary.unallocatedBalance > 0,
                    alignEnd: true,
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: emphasize ? const Color(0xFFBFF0C9) : Colors.white,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "New" allowance pill button
// ---------------------------------------------------------------------------
class _NewAllowanceButton extends StatelessWidget {
  const _NewAllowanceButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Palette.cardBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: _Palette.primaryStart),
              SizedBox(width: 4),
              Text(
                'New',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _Palette.primaryStart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyAllowancesState extends StatelessWidget {
  const _EmptyAllowancesState({required this.onCreate});
  final VoidCallback onCreate;

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
            decoration: BoxDecoration(
              color: const Color(0xFFE3F5DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pie_chart_rounded,
                color: _Palette.primaryStart, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'No allowances yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Split your wallet into budget envelopes to track\nspending by category.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _Palette.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create an allowance'),
            style: TextButton.styleFrom(
              foregroundColor: _Palette.primaryStart,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Ask AI" unallocated balance banner
// ---------------------------------------------------------------------------
class _UnallocatedBanner extends StatelessWidget {
  const _UnallocatedBanner({required this.amount, required this.onAskAi});
  final double amount;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.accentBlueStart, _Palette.accentBlueEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.accentBlueStart.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white, height: 1.4),
                    children: [
                      TextSpan(
                        text: '${_currency.format(amount)} ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(
                        text:
                            'is sitting unallocated. Get a recommendation on what to do with it.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onAskAi,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'Ask AI',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _Palette.accentBlueStart,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Allowance card
// ---------------------------------------------------------------------------
class _AllowanceCard extends StatelessWidget {
  const _AllowanceCard({required this.allowance, required this.colorIndex});
  final Allowance allowance;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final fraction = allowance.allocatedAmount == 0
        ? 0.0
        : (allowance.currentBalance / allowance.allocatedAmount).clamp(0.0, 1.0);

    final bg = _Palette.allowanceIconBg[colorIndex % _Palette.allowanceIconBg.length];
    final fg = _Palette.allowanceIconFg[colorIndex % _Palette.allowanceIconFg.length];
    final isLow = fraction <= 0.2;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddAllowanceSheet(existingAllowance: allowance),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _Palette.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconForAllowance(allowance.name),
                        size: 16, color: fg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allowance.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currency.format(allowance.currentBalance),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3),
                  ),
                  Text(
                    'of ${_currency.format(allowance.allocatedAmount)}',
                    style: const TextStyle(fontSize: 11, color: _Palette.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEFF2ED),
                      valueColor: AlwaysStoppedAnimation(
                        isLow ? _Palette.danger : fg,
                      ),
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

// ---------------------------------------------------------------------------
// Action buttons
// ---------------------------------------------------------------------------
class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.primaryStart,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _Palette.primaryStart,
          disabledForegroundColor: _Palette.textMuted,
          side: BorderSide(
            color: onPressed == null ? _Palette.cardBorder : _Palette.primaryStart,
            width: 1.4,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}