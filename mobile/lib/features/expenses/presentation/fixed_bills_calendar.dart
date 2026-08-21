import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../wallet/domain/wallet_model.dart';
import '../domain/fixed_bill_model.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

enum _DueSource { bill, walletFixedDue }

/// Unified representation of anything that can show up on the calendar —
/// a recurring FixedBill or a one-off reserved wallet Fixed Due transaction.
/// This lets the day grid / bottom sheet render both kinds without caring
/// which underlying model they came from.
class _CalendarEntry {
  final _DueSource source;
  final String name;
  final double amount;
  final bool isPaid;
  final int day;
  final FixedBill? bill;
  final WalletTransactionEntry? walletEntry;

  _CalendarEntry.fromBill(FixedBill b)
      : source = _DueSource.bill,
        name = b.name,
        amount = b.amount,
        isPaid = b.isPaidCurrentCycle,
        day = b.dueDay,
        bill = b,
        walletEntry = null;

  _CalendarEntry.fromWallet(WalletTransactionEntry w)
      : source = _DueSource.walletFixedDue,
        name = (w.description?.isNotEmpty == true) ? w.description! : 'Reserved fixed due',
        amount = w.amount,
        isPaid = w.isPaid,
        day = w.dueDate!.day,
        bill = null,
        walletEntry = w;
}

/// Calendar-style layout combining two "due" sources onto one grid:
/// - FixedBill: recurring every month on `dueDay` (1-31).
/// - Wallet Fixed Due transactions: one-off, only shown in the specific
///   month/year of their `dueDate`.
class FixedBillsCalendarView extends StatefulWidget {
  final List<FixedBill> bills;
  final List<WalletTransactionEntry> walletFixedDues;
  final Future<bool> Function(FixedBill bill) onTogglePaid;
  final void Function(FixedBill bill) onEdit;
  final void Function(FixedBill bill) onDelete;
  final Future<bool> Function(WalletTransactionEntry entry) onPayWalletDue;

  const FixedBillsCalendarView({
    super.key,
    required this.bills,
    this.walletFixedDues = const [],
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
    required this.onPayWalletDue,
  });

  @override
  State<FixedBillsCalendarView> createState() => _FixedBillsCalendarViewState();
}

class _FixedBillsCalendarViewState extends State<FixedBillsCalendarView> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// All entries (bills + wallet dues) applicable to the currently visible
  /// month, bucketed by day-of-month.
  Map<int, List<_CalendarEntry>> get _entriesByDay {
    final map = <int, List<_CalendarEntry>>{};

    for (final bill in widget.bills) {
      final entry = _CalendarEntry.fromBill(bill);
      map.putIfAbsent(entry.day, () => []).add(entry);
    }

    for (final w in widget.walletFixedDues) {
      final due = w.dueDate;
      if (due == null) continue;
      if (due.year != _visibleMonth.year || due.month != _visibleMonth.month) continue;
      final entry = _CalendarEntry.fromWallet(w);
      map.putIfAbsent(entry.day, () => []).add(entry);
    }

    return map;
  }

  List<_CalendarEntry> get _visibleEntries => _entriesByDay.values.expand((e) => e).toList();

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final byDay = _entriesByDay;
    final today = DateTime.now();
    final isCurrentMonth = today.year == _visibleMonth.year && today.month == _visibleMonth.month;

    final visible = _visibleEntries;
    final totalDue = visible.fold<double>(0, (s, e) => s + e.amount);
    final totalUnpaid = visible.where((e) => !e.isPaid).fold<double>(0, (s, e) => s + e.amount);
    final hasAnyEntries = widget.bills.isNotEmpty || widget.walletFixedDues.isNotEmpty;

    return Column(
      children: [
        _MonthHeader(
          month: _visibleMonth,
          onPrev: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'Total This Month',
                  value: _currency.format(totalDue),
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'Still Unpaid',
                  value: _currency.format(totalUnpaid),
                  color: totalUnpaid > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        ),
        const _Legend(),
        const _WeekdayRow(),
        Expanded(
          child: !hasAnyEntries
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No fixed bills or reserved dues yet.\nAdd one to see it on the calendar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: daysInMonth + firstWeekday,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday) return const SizedBox.shrink();
                    final day = index - firstWeekday + 1;
                    final entriesToday = byDay[day] ?? const [];
                    final isToday = isCurrentMonth && today.day == day;

                    return _DayCell(
                      day: day,
                      entries: entriesToday,
                      isToday: isToday,
                      onTap: entriesToday.isEmpty ? null : () => _showDayEntries(context, day, entriesToday),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDayEntries(BuildContext context, int day, List<_CalendarEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DayEntriesSheet(
        day: day,
        entries: entries,
        onTogglePaid: widget.onTogglePaid,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        onPayWalletDue: widget.onPayWalletDue,
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(
            DateFormat.yMMMM().format(month),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _labels
            .map(
              (l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Explains the four dot colors used on the day cells: recurring bill
/// (unpaid/paid) vs reserved wallet Fixed Due (unpaid/paid).
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: const [
          _LegendItem(color: Colors.orange, label: 'Bill due'),
          _LegendItem(color: Colors.green, label: 'Bill paid'),
          _LegendItem(color: Colors.deepPurple, label: 'Reserved'),
          _LegendItem(color: Colors.blue, label: 'Reserved paid'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<_CalendarEntry> entries;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.entries,
    required this.isToday,
    this.onTap,
  });

  Color _dotColor(_CalendarEntry e) {
    if (e.source == _DueSource.bill) {
      return e.isPaid ? Colors.green : Colors.orange;
    }
    return e.isPaid ? Colors.blue : Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries = entries.isNotEmpty;
    final allPaid = hasEntries && entries.every((e) => e.isPaid);
    final anyUnpaid = hasEntries && entries.any((e) => !e.isPaid);

    Color bg = Colors.transparent;
    Color border = Colors.grey.shade200;
    if (hasEntries) {
      if (allPaid) {
        bg = Colors.green.withValues(alpha: 0.10);
        border = Colors.green.withValues(alpha: 0.4);
      } else if (anyUnpaid) {
        bg = Colors.orange.withValues(alpha: 0.10);
        border = Colors.orange.withValues(alpha: 0.4);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? Theme.of(context).colorScheme.primary : border,
            width: isToday ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? Theme.of(context).colorScheme.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            if (hasEntries)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                children: entries
                    .take(4)
                    .map(
                      (e) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _dotColor(e),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (entries.length > 4)
              Text('+${entries.length - 4}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _DayEntriesSheet extends StatelessWidget {
  final int day;
  final List<_CalendarEntry> entries;
  final Future<bool> Function(FixedBill bill) onTogglePaid;
  final void Function(FixedBill bill) onEdit;
  final void Function(FixedBill bill) onDelete;
  final Future<bool> Function(WalletTransactionEntry entry) onPayWalletDue;

  const _DayEntriesSheet({
    required this.day,
    required this.entries,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
    required this.onPayWalletDue,
  });

  Future<void> _handleDeleteBill(BuildContext context, FixedBill b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text('This will permanently remove ${b.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      onDelete(b);
    }
  }

  Future<void> _handlePayWalletDue(BuildContext context, WalletTransactionEntry w) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as paid?'),
        content: Text('This will deduct ${_currency.format(w.amount)} now.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Mark as Paid')),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await onPayWalletDue(w);
    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not mark this as paid. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due on day $day', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...entries.map((e) {
              if (e.source == _DueSource.bill) {
                final b = e.bill!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    icon: Icon(
                      b.isPaidCurrentCycle ? Icons.check_circle : Icons.pending,
                      color: b.isPaidCurrentCycle ? Colors.green : Colors.orange,
                    ),
                    tooltip: b.isPaidCurrentCycle ? 'Mark as unpaid' : 'Mark as paid',
                    onPressed: () async {
                      final success = await onTogglePaid(b);
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not update this bill. Try again.')),
                        );
                      }
                    },
                  ),
                  title: Text(b.name),
                  subtitle: Text(b.isPaidCurrentCycle ? 'Recurring bill • Paid' : 'Recurring bill • Unpaid'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_currency.format(b.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit(b);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _handleDeleteBill(context, b),
                      ),
                    ],
                  ),
                );
              } else {
                final w = e.walletEntry!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    w.isPaid ? Icons.check_circle : Icons.event_busy_rounded,
                    color: w.isPaid ? Colors.blue : Colors.deepPurple,
                  ),
                  title: Text(e.name),
                  subtitle: Text(w.isPaid ? 'Reserved (wallet) • Paid' : 'Reserved (wallet) • Unpaid'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_currency.format(w.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (!w.isPaid) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => _handlePayWalletDue(context, w),
                          child: const Text('Pay', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}