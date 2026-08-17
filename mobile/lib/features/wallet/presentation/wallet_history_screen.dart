import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dateFormat = DateFormat.yMMMd().add_jm();

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadTransactions();
    });
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
                itemBuilder: (context, index) => _TransactionTile(entry: transactions[index]),
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry});
  final WalletTransactionEntry entry;

  IconData get _icon {
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color.withValues(alpha: 0.15),
        child: Icon(_icon, color: _color, size: 20),
      ),
      title: Text(entry.type.label),
      subtitle: Text(
        [
          if (entry.description != null && entry.description!.isNotEmpty) entry.description,
          _dateFormat.format(entry.createdAt),
        ].join(' • '),
      ),
      trailing: Text(
        _currency.format(entry.amount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}