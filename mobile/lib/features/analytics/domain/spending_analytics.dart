// lib/features/analytics/domain/spending_analytics.dart
//
// Pure client-side analytics layer. Reads data already loaded by
// ExpensesProvider (local Expense ledger) and WalletProvider (allowances +
// wallet transactions) — no backend changes required.

import '../../expenses/domain/expense_model.dart';
import '../../wallet/domain/wallet_model.dart';

enum AnalyticsPeriod { last7, last14, last30, custom }

extension AnalyticsPeriodX on AnalyticsPeriod {
  /// Number of days this period covers. Null for custom (caller supplies
  /// explicit start/end dates instead).
  int? get days {
    switch (this) {
      case AnalyticsPeriod.last7:
        return 7;
      case AnalyticsPeriod.last14:
        return 14;
      case AnalyticsPeriod.last30:
        return 30;
      case AnalyticsPeriod.custom:
        return null;
    }
  }

  String get label {
    switch (this) {
      case AnalyticsPeriod.last7:
        return '7 Days';
      case AnalyticsPeriod.last14:
        return '14 Days';
      case AnalyticsPeriod.last30:
        return '30 Days';
      case AnalyticsPeriod.custom:
        return 'Custom';
    }
  }
}

/// One bucketed day of discretionary (non-fixed-due) spending.
class DailySpend {
  final DateTime day; // normalized to local midnight
  final double total;
  DailySpend(this.day, this.total);
}

/// Depletion-risk read for a single allowance, based on how fast it's being
/// drawn down relative to what's left in it.
class AllowanceRisk {
  final String allowanceId;
  final String allowanceName;
  final double currentBalance;
  final double averageDailySpend; // allowance-specific, over the window
  final double? daysUntilDepleted; // null = no recent spend from it
  final bool isAtRisk;

  AllowanceRisk({
    required this.allowanceId,
    required this.allowanceName,
    required this.currentBalance,
    required this.averageDailySpend,
    required this.daysUntilDepleted,
    required this.isAtRisk,
  });
}

class SpendingAnalyticsResult {
  final List<DailySpend> dailyBreakdown;
  final double totalSpent;
  final double averageDailySpend;
  final int daysInWindow;
  final List<AllowanceRisk> allowanceRisks;

  SpendingAnalyticsResult({
    required this.dailyBreakdown,
    required this.totalSpent,
    required this.averageDailySpend,
    required this.daysInWindow,
    required this.allowanceRisks,
  });

  List<AllowanceRisk> get atRiskAllowances =>
      allowanceRisks.where((r) => r.isAtRisk).toList();

  /// Naive linear projection: "if this daily rate keeps up" for [forDays]
  /// more days. Intentionally simple (no seasonality/trend) — it's meant
  /// to be a wake-up-call estimate, not a precise forecast.
  double projectedSpend(int forDays) => averageDailySpend * forDays;
}

class SpendingAnalyticsEngine {
  /// Days-remaining-at-current-rate below which an allowance is flagged
  /// "at risk". 3 days gives the user a heads-up while there's still time
  /// to act — tune to taste.
  static const double riskThresholdDays = 3.0;

  static SpendingAnalyticsResult analyze({
    required List<Expense> expenses,
    required List<Allowance> allowances,
    required List<WalletTransactionEntry> walletTransactions,
    required AnalyticsPeriod period,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    final end = period == AnalyticsPeriod.custom ? (customEnd ?? now) : now;
    final windowEndDay = DateTime(end.year, end.month, end.day);
    final windowStart = period == AnalyticsPeriod.custom
        ? DateTime(
            (customStart ?? end.subtract(const Duration(days: 7))).year,
            (customStart ?? end.subtract(const Duration(days: 7))).month,
            (customStart ?? end.subtract(const Duration(days: 7))).day,
          )
        : windowEndDay.subtract(Duration(days: period.days! - 1));
    final windowEnd = DateTime(windowEndDay.year, windowEndDay.month, windowEndDay.day, 23, 59, 59);
    final daysInWindow = windowEnd.difference(windowStart).inDays + 1;

    // Fixed dues are committed obligations, not discretionary behavior —
    // excluding them keeps the "daily rate" signal meaningful.
    final relevant = expenses.where((e) =>
        e.category != ExpenseCategory.fixedDue &&
        !e.occurredAt.isBefore(windowStart) &&
        !e.occurredAt.isAfter(windowEnd));

    final byDay = <DateTime, double>{};
    for (var i = 0; i < daysInWindow; i++) {
      byDay[windowStart.add(Duration(days: i))] = 0.0;
    }
    double total = 0;
    for (final e in relevant) {
      final day = DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day);
      byDay[day] = (byDay[day] ?? 0) + e.amount;
      total += e.amount;
    }

    final dailyBreakdown = byDay.entries.map((e) => DailySpend(e.key, e.value)).toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    final averageDailySpend = daysInWindow > 0 ? total / daysInWindow : 0.0;

    // Per-allowance burn rate: only WalletTransaction rows carry allowanceId,
    // and only paid expense_allowance transactions represent money that's
    // actually left the envelope (a reserved-but-unpaid Fixed Due hasn't).
    final allowanceRisks = allowances.map((a) {
      final spendTx = walletTransactions.where((t) =>
          t.allowanceId == a.id &&
          t.isPaid &&
          t.type == WalletTransactionType.expenseAllowance &&
          !t.createdAt.isBefore(windowStart) &&
          !t.createdAt.isAfter(windowEnd));

      final allowanceTotal = spendTx.fold<double>(0, (s, t) => s + t.amount);
      final allowanceDailyAvg = daysInWindow > 0 ? allowanceTotal / daysInWindow : 0.0;

      final daysLeft = allowanceDailyAvg > 0 ? a.currentBalance / allowanceDailyAvg : null;
      final atRisk = daysLeft != null && daysLeft <= riskThresholdDays;

      return AllowanceRisk(
        allowanceId: a.id,
        allowanceName: a.name,
        currentBalance: a.currentBalance,
        averageDailySpend: allowanceDailyAvg,
        daysUntilDepleted: daysLeft,
        isAtRisk: atRisk,
      );
    }).toList();

    return SpendingAnalyticsResult(
      dailyBreakdown: dailyBreakdown,
      totalSpent: total,
      averageDailySpend: averageDailySpend,
      daysInWindow: daysInWindow,
      allowanceRisks: allowanceRisks,
    );
  }
}