class FixedBill {
  final String id;
  final String name;
  final double amount;
  final int dueDay;
  final bool isPaidCurrentCycle;

  FixedBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.isPaidCurrentCycle,
  });

  factory FixedBill.fromJson(Map<String, dynamic> json) {
    return FixedBill(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['due_day'] as int,
      isPaidCurrentCycle: json['is_paid_current_cycle'] as bool,
    );
  }
}