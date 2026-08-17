import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import '../domain/expense_model.dart';
import '../domain/fixed_bill_model.dart';
import 'add_expense_sheet.dart';
import 'add_fixed_bill_sheet.dart';
import 'expenses_provider.dart';
import 'fixed_bills_calendar.dart';

final _currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showFixedBillsCalendar = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _handleTogglePaid(FixedBill bill) async {
    final success = await context.read<ExpensesProvider>().toggleBillPaid(bill);
    if (success && mounted) {
      await context.read<AuthProvider>().refreshCurrentUser();
    }
    return success;
  }

  void _handleEdit(FixedBill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFixedBillSheet(existingBill: bill),
    );
  }

  void _handleDelete(FixedBill bill) {
    context.read<ExpensesProvider>().deleteFixedBill(bill.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpensesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          if (_tabController.index == 1)
            IconButton(
              icon: Icon(_showFixedBillsCalendar ? Icons.view_list : Icons.calendar_month),
              tooltip: _showFixedBillsCalendar ? 'Switch to list view' : 'Switch to calendar view',
              onPressed: () => setState(() => _showFixedBillsCalendar = !_showFixedBillsCalendar),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}), // refresh actions[] when tab changes
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Fixed Bills'),
          ],
        ),
      ),
      body: provider.isLoading && provider.expenses.isEmpty && provider.fixedBills.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => context.read<ExpensesProvider>().loadAll(),
                  child: _ExpensesList(expenses: provider.expenses),
                ),
                _showFixedBillsCalendar
                    ? FixedBillsCalendarView(
                        bills: provider.fixedBills,
                        onTogglePaid: _handleTogglePaid,
                        onEdit: _handleEdit,
                        onDelete: _handleDelete,
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<ExpensesProvider>().loadAll(),
                        child: _FixedBillsList(bills: provider.fixedBills),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => _tabController.index == 0
                ? const AddExpenseSheet()
                : const AddFixedBillSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  const _ExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No expenses yet.\nTap + to add one, or pull down to refresh.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, 'this expense'),
          onDismissed: (_) => context.read<ExpensesProvider>().deleteExpense(e.id),
          child: ListTile(
            leading: CircleAvatar(child: Icon(_iconFor(e.category))),
            title: Text(e.description?.isNotEmpty == true ? e.description! : e.category.label),
            subtitle: Text('${e.category.label} • ${DateFormat.yMMMd().format(e.occurredAt)}'),
            trailing: Text(
              _currencyFormat.format(e.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.essential:
        return Icons.shopping_basket;
      case ExpenseCategory.wants:
        return Icons.celebration;
      case ExpenseCategory.fixedDue:
        return Icons.receipt_long;
    }
  }
}

class _FixedBillsList extends StatelessWidget {
  final List<FixedBill> bills;
  const _FixedBillsList({required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.calendar_month, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No fixed bills yet.\nTap + to add one, or pull down to refresh.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final b = bills[index];
        return Dismissible(
          key: ValueKey(b.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, b.name),
          onDismissed: (_) => context.read<ExpensesProvider>().deleteFixedBill(b.id),
          child: ListTile(
leading: IconButton(
  icon: Icon(
    b.isPaidCurrentCycle ? Icons.check_circle : Icons.pending,
    color: b.isPaidCurrentCycle ? Colors.green : Colors.orange,
  ),
  onPressed: () async {
    final success = await context.read<ExpensesProvider>().toggleBillPaid(b);
    if (success && context.mounted) {
      await context.read<AuthProvider>().refreshCurrentUser();
    }
  },
  tooltip: b.isPaidCurrentCycle ? 'Mark as unpaid' : 'Mark as paid',
),
            title: Text(b.name),
            subtitle: Text('Due on day ${b.dueDay} • ${b.isPaidCurrentCycle ? "Paid" : "Unpaid"}'),
            trailing: Text(
              _currencyFormat.format(b.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddFixedBillSheet(existingBill: b),
              );
            },
          ),
        );
      },
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String label) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete this item?'),
      content: Text('This will permanently remove $label.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return result ?? false;
}