import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../domain/wallet_model.dart';
import 'add_allowance_sheet.dart';
import 'spend_sheet.dart';
import 'transfer_sheet.dart';
import 'wallet_history_screen.dart';
import 'wallet_provider.dart';
import 'wallet_simulator_screen.dart';
import 'wallet_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

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
      // Needed so the calendar widget below has data to show.
      context.read<WalletProvider>().loadTransactions();
    });
  }

  void _openSpend(List<Allowance> allowances) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpendSheet(allowances: allowances),
    );
  }

  void _openAddAllowance() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAllowanceSheet(),
    );
  }

  void _openTransfer(List<Allowance> allowances) {
    if (allowances.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferSheet(allowances: allowances),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpensesScreen(initialTabIndex: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final summary = wallet.summary;
    final pendingFixedDues =
        wallet.transactions.where((t) => !t.isPaid && t.dueDate != null).toList();

    return Scaffold(
      backgroundColor: WalletPalette.canvasBottom,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 70,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.66),
                border: const Border(bottom: BorderSide(color: WalletPalette.hairline)),
              ),
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Wallet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: WalletPalette.ink,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Allowances & budget envelopes',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: WalletPalette.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          GlassIconButton(
            icon: Icons.history_rounded,
            tooltip: 'Transaction history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
            ),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.edit_rounded,
            tooltip: 'Edit profile',
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Log out',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WalletAmbientBackground()),
          wallet.isLoading && summary == null
              ? const Center(child: CircularProgressIndicator())
              : summary == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 40, color: WalletPalette.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              wallet.errorMessage ?? 'Could not load wallet summary.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: WalletPalette.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => Future.wait([
                        context.read<WalletProvider>().loadSummary(),
                        context.read<WalletProvider>().loadTransactions(),
                      ]),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          // -----------------------------------------------
                          // Bento dashboard row: balance widget + calendar
                          // widget, with a floating three-button glass
                          // dock pinned to the seam between this row and
                          // the content below. Layout/positioning kept as
                          // approved — only the tile styling changed.
                          // -----------------------------------------------
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: SizedBox(
                                      height: 188,
                                      child: _BalanceBentoCard(summary: summary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 188,
                                      child: _CalendarBentoCard(
                                        pendingEntries: pendingFixedDues,
                                        onTap: _openCalendar,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 158,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _ActionDock(
                                    onAdd: _openAddAllowance,
                                    onSpend: () => _openSpend(summary.allowances),
                                    onTransfer: summary.allowances.isEmpty
                                        ? null
                                        : () => _openTransfer(summary.allowances),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Reserve space for the dock hanging below the
                          // row, plus breathing room before the next
                          // section.
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Allowances',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: WalletPalette.ink,
                                ),
                              ),
                              if (summary.allowances.isNotEmpty)
                                Text(
                                  '${summary.allowances.length} active',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: WalletPalette.textMuted,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (summary.allowances.isEmpty)
                            _EmptyAllowancesState(onCreate: _openAddAllowance)
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
                        ],
                      ),
                    ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance bento card (left, large) — styled as an Apple-Wallet-style ink
// card: a deep 3-stop gradient, a small decorative "chip" nodding to a
// physical card, tabular figures on the balance so it doesn't jiggle on
// refresh, and the shared glass sheen for that pressed-glass highlight.
// ---------------------------------------------------------------------------
class _BalanceBentoCard extends StatelessWidget {
  const _BalanceBentoCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WalletPalette.primaryStart, WalletPalette.primaryMid, WalletPalette.primaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: WalletPalette.primaryStart.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // A small nod to a physical card's EMV chip — purely
                    // decorative, reinforces the "premium card" read.
                    Container(
                      width: 30,
                      height: 21,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.20)],
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.30)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'WALLET BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.white.withOpacity(0.68),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _currency.format(summary.currentWalletBalance),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Container(height: 1, color: Colors.white.withOpacity(0.16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'ALLOCATED',
                        value: _currency.format(summary.allocatedTotal),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      color: Colors.white.withOpacity(0.16),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'UNALLOCATED',
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
          GlassSheen(radius: radius),
        ],
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
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.5,
            color: Colors.white.withOpacity(0.68),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: emphasize ? const Color(0xFFBFF0C9) : Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar bento card (right, smaller) — reads more like the macOS/iOS
// Calendar app icon: month label + today's date up top, a dot-grid month
// view (circles, not squares) with due dates picked out in solid white.
// ---------------------------------------------------------------------------
class _CalendarBentoCard extends StatelessWidget {
  const _CalendarBentoCard({required this.pendingEntries, required this.onTap});

  final List<WalletTransactionEntry> pendingEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final dueDaysThisMonth = pendingEntries
        .where((t) => t.dueDate!.year == now.year && t.dueDate!.month == now.month)
        .map((t) => t.dueDate!.day)
        .toSet();
    final totalDue = pendingEntries.fold<double>(0, (s, e) => s + e.amount);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WalletPalette.tealStart, WalletPalette.tealEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: WalletPalette.tealStart.withOpacity(0.32),
                blurRadius: 24,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 14, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                color: Colors.white.withOpacity(0.9), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat.MMM().format(now).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white.withOpacity(0.88),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${now.day}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: daysInMonth,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 3.5,
                          crossAxisSpacing: 3.5,
                        ),
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isDue = dueDaysThisMonth.contains(day);
                          final isToday = day == now.day;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDue
                                  ? Colors.white
                                  : Colors.white.withOpacity(isToday ? 0.55 : 0.18),
                              border: (isToday && !isDue)
                                  ? Border.all(color: Colors.white, width: 1.2)
                                  : null,
                              boxShadow: isDue
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.14),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 9),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: pendingEntries.isEmpty
                            ? Colors.white.withOpacity(0.16)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6.5),
                        child: Text(
                          pendingEntries.isEmpty
                              ? 'All bills clear'
                              : '${pendingEntries.length} due · ${_currency.format(totalDue)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: pendingEntries.isEmpty
                                ? Colors.white
                                : WalletPalette.amberStart,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GlassSheen(radius: radius),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating action dock — now a true frosted-glass dock (blurred dark
// glass, like the macOS Dock) instead of a solid white pill, with the
// Spend button enlarged as the primary action.
// ---------------------------------------------------------------------------
class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.onAdd,
    required this.onSpend,
    required this.onTransfer,
  });

  final VoidCallback onAdd;
  final VoidCallback onSpend;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            color: WalletPalette.dockGlassDark,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DockButton(
                icon: Icons.pie_chart_rounded,
                label: 'Add',
                onPressed: onAdd,
              ),
              const SizedBox(width: 10),
              _DockButton(
                icon: Icons.payments_rounded,
                label: 'Spend',
                diameter: 78,
                iconSize: 30,
                gradientColors: const [WalletPalette.accentBlueStart, WalletPalette.accentBlueEnd],
                onPressed: onSpend,
              ),
              const SizedBox(width: 10),
              _DockButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Transfer',
                onPressed: onTransfer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.diameter = 58,
    this.iconSize = 22,
    this.gradientColors,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double diameter;
  final double iconSize;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final colors = disabled
        ? const [Color(0xFF3A443E), Color(0xFF3A443E)]
        : (gradientColors ?? const [Color(0xFF3A4B42), Color(0xFF4C5F54)]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                boxShadow: disabled
                    ? []
                    : [
                        BoxShadow(
                          color: colors.first.withOpacity(0.42),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(icon, color: Colors.white, size: iconSize),
                  ),
                  GlassSheen(radius: BorderRadius.circular(diameter / 2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 9.5,
            color: disabled ? Colors.white.withOpacity(0.32) : Colors.white.withOpacity(0.86),
            letterSpacing: 0.1,
          ),
        ),
      ],
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
    return GlassPanel(
      radius: 22,
      blur: 16,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE1F5E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pie_chart_rounded, color: WalletPalette.primaryStart, size: 24),
          ),
          const SizedBox(height: 14),
          const Text(
            'No allowances yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: WalletPalette.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Split your wallet into budget envelopes to track\nspending by category.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WalletPalette.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create an allowance'),
            style: TextButton.styleFrom(
              foregroundColor: WalletPalette.primaryStart,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WalletPalette.accentBlueStart, WalletPalette.accentBlueEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: WalletPalette.accentBlueStart.withOpacity(0.24),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
                        children: [
                          TextSpan(
                            text: '${_currency.format(amount)} ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(
                            text: 'is sitting unallocated. Get a recommendation on what to do with it.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: onAskAi,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          child: Text(
                            'Ask AI',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: WalletPalette.accentBlueStart,
                              fontSize: 12,
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
          GlassSheen(radius: radius),
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

    final bg = WalletPalette.allowanceIconBg[colorIndex % WalletPalette.allowanceIconBg.length];
    final fg = WalletPalette.allowanceIconFg[colorIndex % WalletPalette.allowanceIconFg.length];
    final isLow = fraction <= 0.2;

    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddAllowanceSheet(existingAllowance: allowance),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WalletPalette.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_iconForAllowance(allowance.name), size: 14, color: fg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allowance.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12.5, color: WalletPalette.ink),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: WalletPalette.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'of ${_currency.format(allowance.allocatedAmount)}',
                    style: const TextStyle(fontSize: 10, color: WalletPalette.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEDF1EC),
                      valueColor: AlwaysStoppedAnimation(isLow ? WalletPalette.danger : fg),
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
