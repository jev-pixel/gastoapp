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
  /// [dueDate] pass this when [category] is 'fixed_due' — required by the
  /// backend in that case.
  /// [isPaidNow] only relevant for 'fixed_due': leave false (default) to
  /// reserve the bill without touching the balance yet.
  Future<bool> spend({
    String? allowanceId,
    required double amount,
    required String category,
    String? description,
    DateTime? dueDate,
    bool isPaidNow = false,
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
        dueDate: dueDate,
        isPaidNow: isPaidNow,
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

  /// Marks a reserved Fixed Due transaction as paid — this is the point
  /// where the wallet/allowance balance actually decreases.
  Future<bool> payPendingExpense(String transactionId) async {
    try {
      await _repository.payPendingExpense(transactionId);
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