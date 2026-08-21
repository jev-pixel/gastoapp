import '../../../core/api_client.dart';
import '../domain/wallet_model.dart';

class WalletRepository {
  final ApiClient _api;

  WalletRepository(this._api);

  Future<WalletSummary> getSummary() async {
    final json = await _api.get('/wallet/summary') as Map<String, dynamic>;
    return WalletSummary.fromJson(json);
  }

  Future<Allowance> createAllowance({
    required String name,
    required double allocatedAmount,
  }) async {
    final json = await _api.post('/wallet/allowances', {
      'name': name,
      'allocated_amount': allocatedAmount,
    });
    return Allowance.fromJson(json);
  }

  Future<Allowance> resizeAllowance({
    required String id,
    required double allocatedAmount,
  }) async {
    final json = await _api.patch('/wallet/allowances/$id', {
      'allocated_amount': allocatedAmount,
    });
    return Allowance.fromJson(json);
  }

  Future<void> deleteAllowance(String id) => _api.delete('/wallet/allowances/$id');

  /// [allowanceId] null = pay from unallocated funds directly.
  /// [dueDate] required by the backend when [category] is 'fixed_due'.
  /// [isPaidNow] only matters for 'fixed_due': false (default) reserves the
  /// expense without touching the balance; true deducts immediately like
  /// every other category.
  Future<WalletTransactionEntry> createExpense({
    String? allowanceId,
    required double amount,
    required String category,
    String? description,
    String? idempotencyKey,
    DateTime? dueDate,
    bool isPaidNow = false,
  }) async {
    final json = await _api.post('/wallet/expenses', {
      'allowance_id': allowanceId,
      'amount': amount,
      'category': category,
      'description': description,
      'idempotency_key': idempotencyKey,
      'due_date': dueDate?.toIso8601String(),
      'is_paid_now': isPaidNow,
    });
    return WalletTransactionEntry.fromJson(json);
  }

  /// Settles a previously-reserved Fixed Due transaction: deducts the
  /// balance now and marks it paid.
  Future<WalletTransactionEntry> payPendingExpense(String transactionId) async {
    final json = await _api.post('/wallet/expenses/$transactionId/pay', {});
    return WalletTransactionEntry.fromJson(json);
  }

  /// Either [fromAllowanceId] or [toAllowanceId] (or both) may be null to
  /// mean "unallocated" on that side of the transfer.
  Future<WalletTransactionEntry> transfer({
    String? fromAllowanceId,
    String? toAllowanceId,
    required double amount,
  }) async {
    final json = await _api.post('/wallet/transfer', {
      'from_allowance_id': fromAllowanceId,
      'to_allowance_id': toAllowanceId,
      'amount': amount,
    });
    return WalletTransactionEntry.fromJson(json);
  }

  Future<List<WalletTransactionEntry>> listTransactions({int skip = 0, int limit = 50}) async {
    final data = await _api.get('/wallet/transactions?skip=$skip&limit=$limit') as List<dynamic>;
    return data.map((e) => WalletTransactionEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UnallocatedSimulationResult> simulateUnallocated({String? goalDescription}) async {
    final json = await _api.post('/wallet/simulate-unallocated', {
      'goal_description': goalDescription,
    });
    return UnallocatedSimulationResult.fromJson(json);
  }
}