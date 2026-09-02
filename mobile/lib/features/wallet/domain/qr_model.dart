class QrReservation {
  final String id;
  final String cardWalletId;
  final double amount;
  final String provider;
  final String? merchantName;
  final String? destinationAccount;
  final String status;
  final DateTime expiresAt;

  QrReservation({
    required this.id,
    required this.cardWalletId,
    required this.amount,
    required this.provider,
    this.merchantName,
    this.destinationAccount,
    required this.status,
    required this.expiresAt,
  });

  factory QrReservation.fromJson(Map<String, dynamic> json) => QrReservation(
        id: json['id'] as String,
        cardWalletId: json['card_wallet_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        provider: json['provider'] as String,
        merchantName: json['merchant_name'] as String?,
        destinationAccount: json['destination_account'] as String?,
        status: json['status'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}

/// Mirrors app/api/v1/endpoints/qr.py's _DEEP_LINKS. Kept client-side too so
/// the scan flow doesn't need a round trip just to know which scheme to try.
const Map<String, Map<String, String>> bankDeepLinks = {
  'gcash': {
    'scheme': 'gcash://',
    'storeAndroid': 'https://play.google.com/store/apps/details?id=com.globe.gcash.android',
    'storeIos': 'https://apps.apple.com/ph/app/gcash/id520020791',
  },
  'maya': {
    'scheme': 'paymaya://',
    'storeAndroid': 'https://play.google.com/store/apps/details?id=com.paymaya',
    'storeIos': 'https://apps.apple.com/ph/app/maya/id924768728',
  },
  'unionbank': {
    'scheme': 'ubp://',
    'storeAndroid': 'https://play.google.com/store/apps/details?id=com.unionbankph.online',
    'storeIos': 'https://apps.apple.com/ph/app/unionbank-online/id1177532820',
  },
  'bdo': {
    'scheme': 'bdo.online://',
    'storeAndroid': 'https://play.google.com/store/apps/details?id=com.bdo.pay',
    'storeIos': 'https://apps.apple.com/ph/app/bdo-digital-banking/id1130320737',
  },
};