import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../analytics/presentation/spending_analytics_screen.dart';
import '../domain/wallet_model.dart';
import 'wallet_provider.dart';
import 'wallet_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dateFormat = DateFormat.yMMMd().add_jm();
final _dueDateFormat = DateFormat.yMMMd();

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  bool _payingId = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadTransactions();
    });
  }

  Future<void> _handlePay(WalletTransactionEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Mark as paid?'),
        content: Text(
          'This will deduct ${_currency.format(entry.amount)} from your '
          '${entry.allowanceId != null ? "allowance" : "unallocated funds"} now.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _payingId = true);
    final provider = context.read<WalletProvider>();
    final success = await provider.payPendingExpense(entry.id);
    if (!mounted) return;
    setState(() => _payingId = false);

    if (!success && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<WalletProvider>().transactions;

    return Scaffold(
      backgroundColor: WalletPalette.canvasBottom,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
        title: const Text(
          'Wallet History',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: WalletPalette.ink),
        ),
        actions: [
          GlassIconButton(
            icon: Icons.insights_rounded,
            tooltip: 'Spending analytics',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SpendingAnalyticsScreen()),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WalletAmbientBackground()),
          transactions.isEmpty
              ? const Center(
                  child: Text('No transactions yet.', style: TextStyle(color: WalletPalette.textMuted)))
              : RefreshIndicator(
                  onRefresh: () => context.read<WalletProvider>().loadTransactions(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _TransactionTile(
                      entry: transactions[index],
                      isBusy: _payingId,
                      onPay: () => _handlePay(transactions[index]),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry, required this.isBusy, required this.onPay});

  final WalletTransactionEntry entry;
  final bool isBusy;
  final VoidCallback onPay;

  bool get _isPendingFixedDue => !entry.isPaid;

  IconData get _icon {
    if (_isPendingFixedDue) return Icons.event_busy_rounded;
    switch (entry.type) {
      case WalletTransactionType.allocation:
        return Icons.arrow_downward;
      case WalletTransactionType.deallocation:
        return Icons.arrow_upward;
      case WalletTransactionType.expenseAllowance:
      case WalletTransactionType.expenseUnallocated:
        return Icons.shopping_bag_outlined;
      case WalletTransactionType.transfer:
        return Icons.swap_horiz;
      case WalletTransactionType.cardAllowance:
        return Icons.credit_card;
      case WalletTransactionType.cardExpense:
        return Icons.shopping_bag_outlined;
    }
  }

  Color get _color {
    if (_isPendingFixedDue) return WalletPalette.amberStart;
    switch (entry.type) {
      case WalletTransactionType.allocation:
        return WalletPalette.accentBlueStart;
      case WalletTransactionType.deallocation:
        return WalletPalette.textMuted;
      case WalletTransactionType.expenseAllowance:
      case WalletTransactionType.expenseUnallocated:
        return WalletPalette.danger;
      case WalletTransactionType.transfer:
        return const Color(0xFF6C5CE7);
      case WalletTransactionType.cardAllowance:
        return WalletPalette.accentBlueStart;
      case WalletTransactionType.cardExpense:
        return WalletPalette.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (entry.description != null && entry.description!.isNotEmpty) entry.description!,
      if (entry.dueDate != null) 'Due ${_dueDateFormat.format(entry.dueDate!)}',
      _dateFormat.format(entry.createdAt),
    ];

    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isPendingFixedDue && !isBusy ? onPay : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WalletPalette.glassBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: _color.withOpacity(0.14),
              child: Icon(_icon, color: _color, size: 20),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(entry.type.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: WalletPalette.ink)),
                ),
                if (_isPendingFixedDue) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: WalletPalette.amberStart.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UNPAID',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: WalletPalette.amberStart),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(subtitleParts.join(' • '), style: const TextStyle(color: WalletPalette.textMuted)),
            isThreeLine: false,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currency.format(entry.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: WalletPalette.ink),
                ),
                if (_isPendingFixedDue) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 26,
                    child: TextButton(
                      onPressed: isBusy ? null : onPay,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: WalletPalette.primaryStart,
                      ),
                      child: const Text('Mark as Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}