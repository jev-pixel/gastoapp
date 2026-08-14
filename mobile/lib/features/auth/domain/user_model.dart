class User {
  final String id;
  final String email;
  final String fullName;
  final double monthlyIncome;
  final double targetSavingsFloor;
  final double currentWalletBalance;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.monthlyIncome,
    required this.targetSavingsFloor,
    required this.currentWalletBalance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      monthlyIncome: (json['monthly_income'] as num).toDouble(),
      targetSavingsFloor: (json['target_savings_floor'] as num).toDouble(),
      currentWalletBalance: (json['current_wallet_balance'] as num).toDouble(),
    );
  }
}