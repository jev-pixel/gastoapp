class CompromiseOption {
  final String action;
  final double newAmount;
  final String impactDescription;

  CompromiseOption({required this.action, required this.newAmount, required this.impactDescription});

  factory CompromiseOption.fromJson(Map<String, dynamic> json) {
    return CompromiseOption(
      action: json['action'] as String,
      newAmount: (json['new_amount'] as num).toDouble(),
      impactDescription: json['impact_description'] as String,
    );
  }
}

class ScenarioResult {
  final String verdict;
  final String verdictSummary;
  final String riskLevel;
  final double postExpenseDailyBudget;
  final String tradeOffAnalysis;
  final List<CompromiseOption> compromiseOptions;

  ScenarioResult({
    required this.verdict,
    required this.verdictSummary,
    required this.riskLevel,
    required this.postExpenseDailyBudget,
    required this.tradeOffAnalysis,
    required this.compromiseOptions,
  });

  factory ScenarioResult.fromJson(Map<String, dynamic> json) {
    return ScenarioResult(
      verdict: json['verdict'] as String,
      verdictSummary: json['verdict_summary'] as String,
      riskLevel: json['risk_level'] as String,
      postExpenseDailyBudget: (json['post_expense_daily_budget'] as num).toDouble(),
      tradeOffAnalysis: json['trade_off_analysis'] as String,
      compromiseOptions: (json['compromise_options'] as List<dynamic>)
          .map((e) => CompromiseOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}