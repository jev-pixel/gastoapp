import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api_client.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_model.dart';

const _uuid = Uuid();

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;

  WalletProvider(this._repository);

  WalletSummary? summary;
  List<WalletTransactionEntry> transactions = [];
  UnallocatedSimulationResult? lastSimulation;
  bool isLoading = false;
  bool isSimulating = false;
  String? errorMessage;

  Future<void> loadSummary() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _repository.getSummary();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    try {
      transactions = await _repository.listTransactions();
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<bool> createAllowance({required String name, required double allocatedAmount}) async {
    try {
      await _repository.createAllowance(name: name, allocatedAmount: allocatedAmount);
      await loadSummary();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resizeAllowance({required String id, required double allocatedAmount}) async {
    try {
      await _repository.resizeAllowance(id: id, allocatedAmount: allocatedAmount);
      await loadSummary();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllowance(String id) async {
    try {
      await _repository.deleteAllowance(id);
      await loadSummary();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// [allowanceId] null = pay from unallocated funds directly.
  Future<bool> spend({
    String? allowanceId,
    required double amount,
    required String category,
    String? description,
  }) async {
    try {
      // Generated fresh per attempt, so a double-tap retry with the exact
      // same key would be rejected server-side rather than double-charging.
      await _repository.createExpense(
        allowanceId: allowanceId,
        amount: amount,
        category: category,
        description: description,
        idempotencyKey: _uuid.v4(),
      );
      await loadSummary();
      await loadTransactions();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> transfer({
    String? fromAllowanceId,
    String? toAllowanceId,
    required double amount,
  }) async {
    try {
      await _repository.transfer(
        fromAllowanceId: fromAllowanceId,
        toAllowanceId: toAllowanceId,
        amount: amount,
      );
      await loadSummary();
      await loadTransactions();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> simulateUnallocated({String? goalDescription}) async {
    isSimulating = true;
    errorMessage = null;
    notifyListeners();
    try {
      lastSimulation = await _repository.simulateUnallocated(goalDescription: goalDescription);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isSimulating = false;
      notifyListeners();
    }
  }
}