import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api_client.dart';
import '../data/card_wallet_repository.dart';
import '../domain/card_wallet_model.dart';
import '../domain/wallet_model.dart';

const _uuid = Uuid();

class CardWalletProvider extends ChangeNotifier {
  final CardWalletRepository _repository;
  CardWalletProvider(this._repository);

  List<CardWallet> cardWallets = [];
  final Map<String, List<WalletTransactionEntry>> transactionsByWallet = {};
  bool isLoading = false;
  String? errorMessage;

  CardWallet? byId(String id) {
    for (final w in cardWallets) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<void> loadCardWallets() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cardWallets = await _repository.listCardWallets();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCardWallet({
    required String provider,
    required String name,
    double currentBalance = 0,
  }) async {
    try {
      await _repository.createCardWallet(provider: provider, name: name, currentBalance: currentBalance);
      await loadCardWallets();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameCardWallet({required String id, required String name}) async {
    try {
      await _repository.renameCardWallet(id: id, name: name);
      await loadCardWallets();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCardWallet(String id) async {
    try {
      await _repository.deleteCardWallet(id);
      await loadCardWallets();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadTransactions(String cardWalletId) async {
    try {
      transactionsByWallet[cardWalletId] = await _repository.listTransactions(cardWalletId);
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<bool> addAllowance({required String cardWalletId, required double amount, String? description}) async {
    try {
      await _repository.addAllowance(
        cardWalletId: cardWalletId, amount: amount, description: description, idempotencyKey: _uuid.v4(),
      );
      await loadCardWallets();
      await loadTransactions(cardWalletId);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> spend({required String cardWalletId, required double amount, String? description}) async {
    try {
      await _repository.spend(
        cardWalletId: cardWalletId, amount: amount, description: description, idempotencyKey: _uuid.v4(),
      );
      await loadCardWallets();
      await loadTransactions(cardWalletId);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> transfer({
    String? fromCardWalletId,
    bool fromPhysical = false,
    String? toCardWalletId,
    bool toPhysical = false,
    required double amount,
  }) async {
    try {
      await _repository.transfer(
        fromCardWalletId: fromCardWalletId, fromPhysical: fromPhysical,
        toCardWalletId: toCardWalletId, toPhysical: toPhysical, amount: amount,
      );
      await loadCardWallets();
      if (fromCardWalletId != null) await loadTransactions(fromCardWalletId);
      if (toCardWalletId != null) await loadTransactions(toCardWalletId);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}