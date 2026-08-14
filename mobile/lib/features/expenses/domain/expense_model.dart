enum ExpenseCategory { essential, wants, fixedDue }

extension ExpenseCategoryX on ExpenseCategory {
  String get apiValue {
    switch (this) {
      case ExpenseCategory.essential:
        return 'essential';
      case ExpenseCategory.wants:
        return 'wants';
      case ExpenseCategory.fixedDue:
        return 'fixed_due';
    }
  }

  String get label {
    switch (this) {
      case ExpenseCategory.essential:
        return 'Essential';
      case ExpenseCategory.wants:
        return 'Wants';
      case ExpenseCategory.fixedDue:
        return 'Fixed Due';
    }
  }

  static ExpenseCategory fromApiValue(String value) {
    switch (value) {
      case 'essential':
        return ExpenseCategory.essential;
      case 'wants':
        return ExpenseCategory.wants;
      case 'fixed_due':
        return ExpenseCategory.fixedDue;
      default:
        throw ArgumentError('Unknown category: $value');
    }
  }
}

class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String? description;
  final DateTime occurredAt;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.occurredAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategoryX.fromApiValue(json['category'] as String),
      description: json['description'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
    );
  }
}