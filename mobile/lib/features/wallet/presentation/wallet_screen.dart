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

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

// ---------------------------------------------------------------------------
// Design tokens — kept local so the file stays drop-in without touching
// your app-wide theme. Feel free to move these into ThemeData later.
//
// Visual direction: a "widget dashboard" bento layout (macOS/iOS Big Sur
// style) — big soft-rounded squircle tiles, gentle top-left glass sheen on
// every gradient tile, and a floating three-button action dock that hangs
// well below the bento row, echoing a macOS dock. The dock is the largest,
// most prominent element on the screen; everything else is sized to feel
// proportionate to it rather than competing with it.
// ---------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const accentBlueStart = Color(0xFF2E6ADE);
  static const accentBlueEnd = Color(0xFF5B9BF0);
  static const amberStart = Color(0xFFC77D1E);
  static const amberEnd = Color(0xFFE0A23D);
  static const tealStart = Color(0xFF117F72);
  static const tealEnd = Color(0xFF1FBFAA);
  static const dockDark = Color(0xFF16241E);
  static const dockDarkAlt = Color(0xFF223A2F);
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit profile',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _Palette.primaryStart,
            ),
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _Palette.primaryStart,
            ),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
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
                  onRefresh: () => Future.wait([
                    context.read<WalletProvider>().loadSummary(),
                    context.read<WalletProvider>().loadTransactions(),
                  ]),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // -----------------------------------------------------
                      // Bento dashboard row: balance widget + calendar
                      // widget, with a floating three-button dock hanging
                      // well below the row (not hugging its bottom edge)
                      // so it reads as its own prominent control cluster —
                      // the "signature" macOS-widget touch. Centered via a
                      // full-width Center wrapper so it stays centered on
                      // the screen regardless of the bento row's width.
                      // -----------------------------------------------------
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
                                  height: 196,
                                  child: _BalanceBentoCard(summary: summary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 196,
                                  child: _CalendarBentoCard(
                                    pendingEntries: pendingFixedDues,
                                    onTap: _openCalendar,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Pushed further down (was -48) so the dock hangs
                          // clearly below the bento row instead of
                          // overlapping its bottom edge.
                          Positioned(
                            bottom: -78,
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
                      // Reserve space for the larger, lower-hanging dock,
                      // plus breathing room before the next section.
                      const SizedBox(height: 100),
                      const Text(
                        'Allowances',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
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
                            childAspectRatio: 1.3,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative glass "sheen" — a soft diagonal highlight pinned to the
// top-left of a gradient tile, the detail that reads as "macOS widget"
// rather than a flat colored card. Purely cosmetic, never intercepts taps.
// ---------------------------------------------------------------------------
class _GlassSheen extends StatelessWidget {
  const _GlassSheen({required this.radius});
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: radius,
          child: Align(
            alignment: Alignment.topLeft,
            child: FractionallySizedBox(
              widthFactor: 0.75,
              heightFactor: 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.16),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance bento card (left, large)
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
          colors: [_Palette.primaryStart, _Palette.primaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.primaryStart.withOpacity(0.30),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WALLET BALANCE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _currency.format(summary.currentWalletBalance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(0.16)),
                const SizedBox(height: 13),
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
                      height: 28,
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
          _GlassSheen(radius: radius),
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
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: emphasize ? const Color(0xFFBFF0C9) : Colors.white,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar bento card (right, smaller) — a mini dot-grid "widget" of the
// current month, with due days picked out, plus a reserved-bills chip.
// Tapping it opens the Fixed Bills calendar.
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
              colors: [_Palette.tealStart, _Palette.tealEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: _Palette.tealStart.withOpacity(0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 15, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            color: Colors.white.withOpacity(0.9), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'CALENDAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white.withOpacity(0.85),
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
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                        ),
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isDue = dueDaysThisMonth.contains(day);
                          final isToday = day == now.day;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: isDue
                                  ? Colors.white
                                  : Colors.white.withOpacity(isToday ? 0.55 : 0.22),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 9),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: pendingEntries.isEmpty
                            ? Colors.white.withOpacity(0.18)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(9),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: pendingEntries.isEmpty
                                ? Colors.white
                                : _Palette.amberStart,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _GlassSheen(radius: radius),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating three-button action dock — the signature element, now the
// clearly dominant control on the screen. Diameters bumped up again
// (66->84 / 92->116) and it hangs 78px below the bento row (was 48), so it
// reads as its own prominent cluster with breathing room on every side
// rather than tucking under the cards above it.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _DockButton(
          icon: Icons.pie_chart_rounded,
          label: 'Add',
          onPressed: onAdd,
        ),
        const SizedBox(width: 20),
        _DockButton(
          icon: Icons.payments_rounded,
          label: 'Spend',
          diameter: 116,
          iconSize: 44,
          gradientColors: const [_Palette.accentBlueStart, _Palette.accentBlueEnd],
          onPressed: onSpend,
        ),
        const SizedBox(width: 20),
        _DockButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer',
          onPressed: onTransfer,
        ),
      ],
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.diameter = 84,
    this.iconSize = 30,
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
        ? const [Color(0xFFB9C2BC), Color(0xFFB9C2BC)]
        : (gradientColors ?? const [_Palette.dockDark, _Palette.dockDarkAlt]);

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
                border: Border.all(color: _Palette.surface, width: 5),
                boxShadow: disabled
                    ? []
                    : [
                        BoxShadow(
                          color: colors.first.withOpacity(0.42),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(icon, color: Colors.white, size: iconSize),
                  ),
                  _GlassSheen(radius: BorderRadius.circular(diameter / 2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: disabled ? _Palette.textMuted : _Palette.primaryStart,
            letterSpacing: 0.15,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            style: TextStyle(color: _Palette.textMuted, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create an allowance'),
            style: TextButton.styleFrom(
              foregroundColor: _Palette.primaryStart,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
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
      padding: const EdgeInsets.all(15),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.white, height: 1.4),
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
                              EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                          child: Text(
                            'Ask AI',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _Palette.accentBlueStart,
                              fontSize: 12.5,
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
          _GlassSheen(radius: radius),
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
            border: Border.all(color: _Palette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForAllowance(allowance.name),
                        size: 15, color: fg),
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