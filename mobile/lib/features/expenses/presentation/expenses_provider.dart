import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/expense_repository.dart';
import '../domain/expense_model.dart';
import '../domain/fixed_bill_model.dart';

class ExpensesProvider extends ChangeNotifier {
  final ExpenseRepository _repository;

  ExpensesProvider(this._repository) {
    _expensesSub = _repository.watchExpenses().listen((data) {
      expenses = data;
      notifyListeners();
    });
    _billsSub = _repository.watchFixedBills().listen((data) {
      fixedBills = data;
      notifyListeners();
    });
  }

  StreamSubscription<List<Expense>>? _expensesSub;
  StreamSubscription<List<FixedBill>>? _billsSub;

  List<Expense> expenses = [];
  List<FixedBill> fixedBills = [];
  bool isLoading = false;
  String? errorMessage;

  /// Pull-to-refresh entry point. The local streams above already keep the
  /// UI live from the on-device cache; this just asks the repository to
  /// reconcile with the server when possible (no-op if offline).
  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.refreshFromServer();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required double amount,
    required ExpenseCategory category,
    String? description,
  }) {
    return _repository.addExpense(amount: amount, category: category, description: description);
  }

  Future<bool> deleteExpense(String id) => _repository.deleteExpense(id);

  Future<bool> addFixedBill({
    required String name,
    required double amount,
    required int dueDay,
  }) {
    return _repository.addFixedBill(name: name, amount: amount, dueDay: dueDay);
  }

  Future<bool> updateFixedBill({
    required String id,
    String? name,
    double? amount,
    int? dueDay,
  }) {
    return _repository.updateFixedBill(id: id, name: name, amount: amount, dueDay: dueDay);
  }

  Future<bool> toggleBillPaid(FixedBill bill) => _repository.toggleBillPaid(bill);

  Future<bool> deleteFixedBill(String id) => _repository.deleteFixedBill(id);

  double get totalUnpaidFixedDues => fixedBills
      .where((b) => !b.isPaidCurrentCycle)
      .fold(0.0, (sum, b) => sum + b.amount);

  @override
  void dispose() {
    _expensesSub?.cancel();
    _billsSub?.cancel();
    super.dispose();
  }
}