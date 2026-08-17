import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/fixed_bill_model.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

/// Calendar-style layout for Fixed Bills. Bills only carry a `dueDay`
/// (1-31, recurring every cycle) — not a specific month/year — so every
/// month shown here displays the same recurring set of bills on their
/// due days. This mirrors the existing backend/data model; no schema
/// changes are required to use this widget.
class FixedBillsCalendarView extends StatefulWidget {
  final List<FixedBill> bills;
  final Future<bool> Function(FixedBill bill) onTogglePaid;
  final void Function(FixedBill bill) onEdit;
  final void Function(FixedBill bill) onDelete;

  const FixedBillsCalendarView({
    super.key,
    required this.bills,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<FixedBillsCalendarView> createState() => _FixedBillsCalendarViewState();
}

class _FixedBillsCalendarViewState extends State<FixedBillsCalendarView> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Map<int, List<FixedBill>> get _billsByDay {
    final map = <int, List<FixedBill>>{};
    for (final bill in widget.bills) {
      map.putIfAbsent(bill.dueDay, () => []).add(bill);
    }
    return map;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    // 0 = Sunday, matching the weekday header row below.
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final byDay = _billsByDay;
    final today = DateTime.now();
    final isCurrentMonth = today.year == _visibleMonth.year && today.month == _visibleMonth.month;

    final totalDue = widget.bills.fold<double>(0, (s, b) => s + b.amount);
    final totalUnpaid = widget.bills
        .where((b) => !b.isPaidCurrentCycle)
        .fold<double>(0, (s, b) => s + b.amount);

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
                  label: 'Total Bills',
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
        const _WeekdayRow(),
        Expanded(
          child: widget.bills.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No fixed bills yet.\nAdd one to see it on the calendar.',
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
                    final billsToday = byDay[day] ?? const [];
                    final isToday = isCurrentMonth && today.day == day;

                    return _DayCell(
                      day: day,
                      bills: billsToday,
                      isToday: isToday,
                      onTap: billsToday.isEmpty ? null : () => _showDayBills(context, day, billsToday),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDayBills(BuildContext context, int day, List<FixedBill> bills) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DayBillsSheet(
        day: day,
        bills: bills,
        onTogglePaid: widget.onTogglePaid,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
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
  final List<FixedBill> bills;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.bills,
    required this.isToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBills = bills.isNotEmpty;
    final allPaid = hasBills && bills.every((b) => b.isPaidCurrentCycle);
    final anyUnpaid = hasBills && bills.any((b) => !b.isPaidCurrentCycle);

    Color bg = Colors.transparent;
    Color border = Colors.grey.shade200;
    if (hasBills) {
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
            if (hasBills)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                children: bills
                    .take(3)
                    .map(
                      (b) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: b.isPaidCurrentCycle ? Colors.green : Colors.orange,
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (bills.length > 3)
              Text('+${bills.length - 3}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _DayBillsSheet extends StatelessWidget {
  final int day;
  final List<FixedBill> bills;
  final Future<bool> Function(FixedBill bill) onTogglePaid;
  final void Function(FixedBill bill) onEdit;
  final void Function(FixedBill bill) onDelete;

  const _DayBillsSheet({
    required this.day,
    required this.bills,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _handleDelete(BuildContext context, FixedBill b) async {
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
      Navigator.of(context).pop(); // close the day-bills sheet
      onDelete(b);
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
            ...bills.map(
              (b) => ListTile(
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
                subtitle: Text(b.isPaidCurrentCycle ? 'Paid' : 'Unpaid'),
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
                      onPressed: () => _handleDelete(context, b),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}