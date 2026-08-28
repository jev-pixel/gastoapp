class Allowance {
  final String id;
  final String name;
  final double allocatedAmount;
  final double currentBalance;

  Allowance({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.currentBalance,
  });

  factory Allowance.fromJson(Map<String, dynamic> json) {
    return Allowance(
      id: json['id'] as String,
      name: json['name'] as String,
      allocatedAmount: (json['allocated_amount'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
    );
  }
}

class WalletSummary {
  final double currentWalletBalance;
  final double allocatedTotal;
  final double unallocatedBalance;
  final List<Allowance> allowances;

  WalletSummary({
    required this.currentWalletBalance,
    required this.allocatedTotal,
    required this.unallocatedBalance,
    required this.allowances,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      currentWalletBalance: (json['current_wallet_balance'] as num).toDouble(),
      allocatedTotal: (json['allocated_total'] as num).toDouble(),
      unallocatedBalance: (json['unallocated_balance'] as num).toDouble(),
      allowances: (json['allowances'] as List<dynamic>)
          .map((e) => Allowance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum WalletTransactionType {
  allocation,
  deallocation,
  expenseAllowance,
  expenseUnallocated,
  transfer,
  cardAllowance,   // NEW
  cardExpense,     // NEW
}

extension WalletTransactionTypeX on WalletTransactionType {
  String get label {
    switch (this) {
      case WalletTransactionType.allocation:
        return 'Allocated';
      case WalletTransactionType.deallocation:
        return 'Deallocated';
      case WalletTransactionType.expenseAllowance:
        return 'Spent (Allowance)';
      case WalletTransactionType.expenseUnallocated:
        return 'Spent (Unallocated)';
      case WalletTransactionType.transfer:
        return 'Transfer';
      case WalletTransactionType.cardAllowance:   // NEW
        return 'Added (Card)';
      case WalletTransactionType.cardExpense:      // NEW
        return 'Spent (Card)';
    }
  }

   static WalletTransactionType fromApiValue(String value) {
    switch (value) {
      case 'allocation':
        return WalletTransactionType.allocation;
      case 'deallocation':
        return WalletTransactionType.deallocation;
      case 'expense_allowance':
        return WalletTransactionType.expenseAllowance;
      case 'expense_unallocated':
        return WalletTransactionType.expenseUnallocated;
      case 'transfer':
        return WalletTransactionType.transfer;
      case 'card_allowance':          // NEW
        return WalletTransactionType.cardAllowance;
      case 'card_expense':            // NEW
        return WalletTransactionType.cardExpense;
      default:
        throw ArgumentError('Unknown transaction type: $value');
    }
  }
}

class WalletTransactionEntry {
  final String id;
  final WalletTransactionType type;
  final double amount;
  final String? description;
  final String? allowanceId;
  final String? fromAllowanceId;
  final String? toAllowanceId;
  final String? cardWalletId;
  final String? fromCardWalletId;
  final String? toCardWalletId;
  // Populated only for Fixed Due expenses — the date the bill is due.
  final DateTime? dueDate;
  // False = this is a reserved-but-unpaid Fixed Due; the wallet/allowance
  // balance has not been deducted yet. True for everything else (and for
  // a Fixed Due once it's been paid).
  final bool isPaid;
  final DateTime createdAt;

  WalletTransactionEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.allowanceId,
    required this.fromAllowanceId,
    required this.toAllowanceId,
    required this.cardWalletId,
    required this.fromCardWalletId,
    required this.toCardWalletId,
    required this.dueDate,
    required this.isPaid,
    required this.createdAt,
  });

  factory WalletTransactionEntry.fromJson(Map<String, dynamic> json) {
    return WalletTransactionEntry(
      id: json['id'] as String,
      type: WalletTransactionTypeX.fromApiValue(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      allowanceId: json['allowance_id'] as String?,
      fromAllowanceId: json['from_allowance_id'] as String?,
      toAllowanceId: json['to_allowance_id'] as String?,
      cardWalletId: json['card_wallet_id'] as String?,
      fromCardWalletId: json['from_card_wallet_id'] as String?,
      toCardWalletId: json['to_card_wallet_id'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      isPaid: json['is_paid'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SuggestedAllocation {
  final String action;
  final String? targetAllowanceName;
  final double suggestedAmount;
  final String reasoning;

  SuggestedAllocation({
    required this.action,
    required this.targetAllowanceName,
    required this.suggestedAmount,
    required this.reasoning,
  });

  factory SuggestedAllocation.fromJson(Map<String, dynamic> json) {
    return SuggestedAllocation(
      action: json['action'] as String,
      targetAllowanceName: json['target_allowance_name'] as String?,
      suggestedAmount: (json['suggested_amount'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
    );
  }
}

class UnallocatedSimulationResult {
  final double unallocatedBalance;
  final String recommendationSummary;
  final String riskNote;
  final List<SuggestedAllocation> suggestedActions;

  UnallocatedSimulationResult({
    required this.unallocatedBalance,
    required this.recommendationSummary,
    required this.riskNote,
    required this.suggestedActions,
  });

  factory UnallocatedSimulationResult.fromJson(Map<String, dynamic> json) {
    return UnallocatedSimulationResult(
      unallocatedBalance: (json['unallocated_balance'] as num).toDouble(),
      recommendationSummary: json['recommendation_summary'] as String,
      riskNote: json['risk_note'] as String,
      suggestedActions: (json['suggested_actions'] as List<dynamic>)
          .map((e) => SuggestedAllocation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}