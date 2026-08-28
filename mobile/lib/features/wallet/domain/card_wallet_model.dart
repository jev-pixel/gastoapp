class CardWallet {
  final String id;
  final String provider;
  final String name;
  final double currentBalance;

  CardWallet({
    required this.id,
    required this.provider,
    required this.name,
    required this.currentBalance,
  });

  factory CardWallet.fromJson(Map<String, dynamic> json) {
    return CardWallet(
      id: json['id'] as String,
      provider: json['provider'] as String,
      name: json['name'] as String,
      currentBalance: (json['current_balance'] as num).toDouble(),
    );
  }
}

const cardProviders = ['BDO', 'GCash', 'Maya', 'UnionBank', 'Other'];