import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

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
      appBar: AppBar(title: const Text('Wallet History')),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: () => context.read<WalletProvider>().loadTransactions(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) => _TransactionTile(
                  entry: transactions[index],
                  isBusy: _payingId,
                  onPay: () => _handlePay(transactions[index]),
                ),
              ),
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
    }
  }

  Color get _color {
    if (_isPendingFixedDue) return Colors.orange;
    switch (entry.type) {
      case WalletTransactionType.allocation:
        return Colors.blue;
      case WalletTransactionType.deallocation:
        return Colors.grey;
      case WalletTransactionType.expenseAllowance:
      case WalletTransactionType.expenseUnallocated:
        return Colors.red;
      case WalletTransactionType.transfer:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (entry.description != null && entry.description!.isNotEmpty) entry.description!,
      if (entry.dueDate != null) 'Due ${_dueDateFormat.format(entry.dueDate!)}',
      _dateFormat.format(entry.createdAt),
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color.withValues(alpha: 0.15),
        child: Icon(_icon, color: _color, size: 20),
      ),
      title: Row(
        children: [
          Flexible(child: Text(entry.type.label)),
          if (_isPendingFixedDue) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'UNPAID',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitleParts.join(' • ')),
      isThreeLine: false,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _currency.format(entry.amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
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
                ),
                child: const Text('Mark as Paid', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}