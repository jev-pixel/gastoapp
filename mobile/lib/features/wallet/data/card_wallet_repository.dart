import '../../../core/api_client.dart';
import '../domain/card_wallet_model.dart';
import '../domain/wallet_model.dart';
import '../domain/qr_model.dart';

class CardWalletRepository {
  final ApiClient _api;
  CardWalletRepository(this._api);

  Future<List<CardWallet>> listCardWallets() async {
    final data = await _api.get('/card-wallets/') as List<dynamic>;
    return data.map((e) => CardWallet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CardWallet> createCardWallet({
    required String provider,
    required String name,
    double currentBalance = 0,
  }) async {
    final json = await _api.post('/card-wallets/', {
      'provider': provider,
      'name': name,
      'current_balance': currentBalance,
    });
    return CardWallet.fromJson(json);
  }

  Future<CardWallet> renameCardWallet({required String id, required String name}) async {
    final json = await _api.patch('/card-wallets/$id', {'name': name});
    return CardWallet.fromJson(json);
  }

  Future<void> deleteCardWallet(String id) => _api.delete('/card-wallets/$id');

  Future<WalletTransactionEntry> addAllowance({
    required String cardWalletId,
    required double amount,
    String? description,
    String? idempotencyKey,
  }) async {
    final json = await _api.post('/card-wallets/$cardWalletId/allowances', {
      'amount': amount,
      'description': description,
      'idempotency_key': idempotencyKey,
    });
    return WalletTransactionEntry.fromJson(json);
  }

  Future<WalletTransactionEntry> spend({
    required String cardWalletId,
    required double amount,
    String? description,
    String? idempotencyKey,
  }) async {
    final json = await _api.post('/card-wallets/$cardWalletId/expenses', {
      'amount': amount,
      'description': description,
      'idempotency_key': idempotencyKey,
    });
    return WalletTransactionEntry.fromJson(json);
  }

  Future<List<WalletTransactionEntry>> listTransactions(String cardWalletId, {int skip = 0, int limit = 50}) async {
    final data = await _api.get('/card-wallets/$cardWalletId/transactions?skip=$skip&limit=$limit') as List<dynamic>;
    return data.map((e) => WalletTransactionEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WalletTransactionEntry> transfer({
    String? fromCardWalletId,
    bool fromPhysical = false,
    String? toCardWalletId,
    bool toPhysical = false,
    required double amount,
  }) async {
    final json = await _api.post('/card-wallets/transfer', {
      'from_card_wallet_id': fromCardWalletId,
      'from_physical': fromPhysical,
      'to_card_wallet_id': toCardWalletId,
      'to_physical': toPhysical,
      'amount': amount,
    });
    return WalletTransactionEntry.fromJson(json);
  }

  Future<QrReservation> reserveQrPayment({
  required String cardWalletId,
  required double amount,
  required String provider,
  String? merchantName,
  String? destinationAccount,
  String? rawPayload,
}) async {
  final json = await _api.post('/wallet/qr/reserve', {
    'card_wallet_id': cardWalletId,
    'amount': amount,
    'provider': provider,
    'merchant_name': merchantName,
    'destination_account': destinationAccount,
    'raw_payload': rawPayload,
  });
  return QrReservation.fromJson(json);
}

Future<QrReservation> settleQrPayment(String reservationId) async {
  final json = await _api.post('/wallet/qr/$reservationId/settle', {});
  return QrReservation.fromJson(json);
}

Future<QrReservation> cancelQrPayment(String reservationId) async {
  final json = await _api.post('/wallet/qr/$reservationId/cancel', {});
  return QrReservation.fromJson(json);
}

}