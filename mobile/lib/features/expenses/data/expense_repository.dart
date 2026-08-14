import '../../../core/api_client.dart';
import '../domain/expense_model.dart';
import '../domain/fixed_bill_model.dart';

class ExpenseRepository {
  final ApiClient _api;

  ExpenseRepository(this._api);

  Future<List<Expense>> listExpenses() async {
    final data = await _api.get('/expenses/') as List<dynamic>;
    return data.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Expense> createExpense({
    required double amount,
    required ExpenseCategory category,
    String? description,
  }) async {
    final json = await _api.post('/expenses/', {
      'amount': amount,
      'category': category.apiValue,
      'description': description,
    });
    return Expense.fromJson(json);
  }

  Future<void> deleteExpense(String id) => _api.delete('/expenses/$id');

  Future<List<FixedBill>> listFixedBills() async {
    final data = await _api.get('/expenses/fixed-bills') as List<dynamic>;
    return data.map((e) => FixedBill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FixedBill> createFixedBill({
    required String name,
    required double amount,
    required int dueDay,
    bool isPaidCurrentCycle = false,
  }) async {
    final json = await _api.post('/expenses/fixed-bills', {
      'name': name,
      'amount': amount,
      'due_day': dueDay,
      'is_paid_current_cycle': isPaidCurrentCycle,
    });
    return FixedBill.fromJson(json);
  }

  Future<FixedBill> updateFixedBill({
    required String id,
    String? name,
    double? amount,
    int? dueDay,
    bool? isPaidCurrentCycle,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (amount != null) body['amount'] = amount;
    if (dueDay != null) body['due_day'] = dueDay;
    if (isPaidCurrentCycle != null) body['is_paid_current_cycle'] = isPaidCurrentCycle;

    final json = await _api.patch('/expenses/fixed-bills/$id', body);
    return FixedBill.fromJson(json);
  }

  Future<void> deleteFixedBill(String id) => _api.delete('/expenses/fixed-bills/$id');

Future<FixedBill> payFixedBill(String id) async {
  final json = await _api.post('/expenses/fixed-bills/$id/pay', {});
  return FixedBill.fromJson(json);
}

Future<FixedBill> unpayFixedBill(String id) async {
  final json = await _api.post('/expenses/fixed-bills/$id/unpay', {});
  return FixedBill.fromJson(json);
}
}