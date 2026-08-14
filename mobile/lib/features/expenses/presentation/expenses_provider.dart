import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/expense_repository.dart';
import '../domain/expense_model.dart';
import '../domain/fixed_bill_model.dart';

class ExpensesProvider extends ChangeNotifier {
  final ExpenseRepository _repository;

  ExpensesProvider(this._repository);

  List<Expense> expenses = [];
  List<FixedBill> fixedBills = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      expenses = await _repository.listExpenses();
      fixedBills = await _repository.listFixedBills();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required double amount,
    required ExpenseCategory category,
    String? description,
  }) async {
    try {
      final expense = await _repository.createExpense(
        amount: amount,
        category: category,
        description: description,
      );
      expenses = [expense, ...expenses];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    final previous = expenses;
    expenses = expenses.where((e) => e.id != id).toList();
    notifyListeners();
    try {
      await _repository.deleteExpense(id);
      return true;
    } on ApiException catch (e) {
      expenses = previous; // rollback on failure
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addFixedBill({
    required String name,
    required double amount,
    required int dueDay,
  }) async {
    try {
      final bill = await _repository.createFixedBill(name: name, amount: amount, dueDay: dueDay);
      fixedBills = [...fixedBills, bill];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFixedBill({
    required String id,
    String? name,
    double? amount,
    int? dueDay,
    bool? isPaidCurrentCycle,
  }) async {
    try {
      final updated = await _repository.updateFixedBill(
        id: id,
        name: name,
        amount: amount,
        dueDay: dueDay,
        isPaidCurrentCycle: isPaidCurrentCycle,
      );
      fixedBills = fixedBills.map((b) => b.id == id ? updated : b).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

Future<bool> toggleBillPaid(FixedBill bill) async {
  try {
    final updated = bill.isPaidCurrentCycle
        ? await _repository.unpayFixedBill(bill.id)
        : await _repository.payFixedBill(bill.id);
    fixedBills = fixedBills.map((b) => b.id == bill.id ? updated : b).toList();
    notifyListeners();
    return true;
  } on ApiException catch (e) {
    errorMessage = e.message;
    notifyListeners();
    return false;
  }
}

  Future<bool> deleteFixedBill(String id) async {
    final previous = fixedBills;
    fixedBills = fixedBills.where((b) => b.id != id).toList();
    notifyListeners();
    try {
      await _repository.deleteFixedBill(id);
      return true;
    } on ApiException catch (e) {
      fixedBills = previous; // rollback on failure
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  double get totalUnpaidFixedDues => fixedBills
      .where((b) => !b.isPaidCurrentCycle)
      .fold(0.0, (sum, b) => sum + b.amount);
}