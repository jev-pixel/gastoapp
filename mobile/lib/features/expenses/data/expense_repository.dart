import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../../core/api_client.dart';
import '../../../core/connectivity_service.dart';
import '../../../core/local_db/database.dart';
import '../domain/expense_model.dart';
import '../domain/fixed_bill_model.dart';

const _uuid = Uuid();
const _localIdPrefix = 'local-'; // marks an id as not-yet-confirmed by the server

/// Offline-first repository. All reads come from the local SQLite cache
/// (via Drift's reactive streams) so the UI always has something to show
/// instantly, online or not. All writes land locally first, then either
/// sync immediately (if online) or wait in the PendingOperations queue
/// (if offline) for SyncService to drain later.
class ExpenseRepository {
  final ApiClient _api;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  /// Must be set right after login (see AuthProvider) so local rows can be
  /// scoped to the right user.
  String? currentUserId;

  ExpenseRepository(this._api, this._db, this._connectivity);

  // ---- Reads (always local; call refreshFromServer() to pull latest) ----

  Stream<List<Expense>> watchExpenses() {
    if (currentUserId == null) return const Stream.empty();
    return _db.watchExpenses(currentUserId!).map(
          (rows) => rows.map(_expenseFromLocal).toList(),
        );
  }

  Stream<List<FixedBill>> watchFixedBills() {
    if (currentUserId == null) return const Stream.empty();
    return _db.watchFixedBills(currentUserId!).map(
          (rows) => rows.map(_billFromLocal).toList(),
        );
  }

  /// Pulls the authoritative list from the API and overwrites local rows
  /// that are already synced (dirty == false). Rows with local changes not
  /// yet pushed are left alone so we don't clobber unsynced edits.
  Future<void> refreshFromServer() async {
    if (currentUserId == null) return;
    if (!await _connectivity.isOnlineNow) return;

    try {
      final expensesJson = await _api.get('/expenses/') as List<dynamic>;
      for (final json in expensesJson) {
        final e = Expense.fromJson(json as Map<String, dynamic>);
        await _db.upsertExpense(_expenseToCompanion(e, currentUserId!));
      }
    } on ApiException {
      // Offline or server hiccup — local cache stays as the source of truth.
    }

    try {
      final billsJson = await _api.get('/expenses/fixed-bills') as List<dynamic>;
      for (final json in billsJson) {
        final b = FixedBill.fromJson(json as Map<String, dynamic>);
        await _db.upsertFixedBill(_billToCompanion(b, currentUserId!));
      }
    } on ApiException {
      // Same as above.
    }
  }

  // ---- Expenses: writes ----

  Future<bool> addExpense({
    required double amount,
    required ExpenseCategory category,
    String? description,
  }) async {
    if (currentUserId == null) return false;
    final localId = '$_localIdPrefix${_uuid.v4()}';
    final occurredAt = DateTime.now();

    await _db.upsertExpense(LocalExpensesCompanion.insert(
      id: localId,
      userId: currentUserId!,
      amount: amount,
      category: category.apiValue,
      description: Value(description),
      occurredAt: occurredAt,
      dirty: const Value(true),
      pendingCreate: const Value(true),
    ));

    await _db.enqueueOperation(PendingOperationsCompanion.insert(
      opType: 'create_expense',
      entityType: 'expense',
      entityId: localId,
      payloadJson: jsonEncode({
        'amount': amount,
        'category': category.apiValue,
        'description': description,
      }),
    ));

    await _trySyncNow();
    return true;
  }

  Future<bool> deleteExpense(String id) async {
    final existing = await (_db.select(_db.localExpenses)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return false;

    if (existing.pendingCreate) {
      // Never reached the server — just remove it and its queued create op.
      await _removeQueuedOpsFor(id);
      await _db.deleteExpenseLocally(id);
      return true;
    }

    await (_db.update(_db.localExpenses)..where((e) => e.id.equals(id)))
        .write(const LocalExpensesCompanion(pendingDelete: Value(true), dirty: Value(true)));

    await _db.enqueueOperation(PendingOperationsCompanion.insert(
      opType: 'delete_expense',
      entityType: 'expense',
      entityId: id,
      payloadJson: '{}',
    ));

    await _trySyncNow();
    return true;
  }

  // ---- Fixed Bills: writes ----

  Future<bool> addFixedBill({
    required String name,
    required double amount,
    required int dueDay,
  }) async {
    if (currentUserId == null) return false;
    final localId = '$_localIdPrefix${_uuid.v4()}';

    await _db.upsertFixedBill(LocalFixedBillsCompanion.insert(
      id: localId,
      userId: currentUserId!,
      name: name,
      amount: amount,
      dueDay: dueDay,
      dirty: const Value(true),
      pendingCreate: const Value(true),
    ));

    await _db.enqueueOperation(PendingOperationsCompanion.insert(
      opType: 'create_bill',
      entityType: 'fixed_bill',
      entityId: localId,
      payloadJson: jsonEncode({
        'name': name,
        'amount': amount,
        'due_day': dueDay,
        'is_paid_current_cycle': false,
      }),
    ));

    await _trySyncNow();
    return true;
  }

  Future<bool> updateFixedBill({
    required String id,
    String? name,
    double? amount,
    int? dueDay,
  }) async {
    final existing =
        await (_db.select(_db.localFixedBills)..where((b) => b.id.equals(id))).getSingleOrNull();
    if (existing == null) return false;

    await (_db.update(_db.localFixedBills)..where((b) => b.id.equals(id))).write(
      LocalFixedBillsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        dueDay: dueDay != null ? Value(dueDay) : const Value.absent(),
        dirty: const Value(true),
      ),
    );

    if (existing.pendingCreate) {
      // Not yet synced — fold the edit into the still-queued create payload
      // instead of adding a second operation.
      await _mergeIntoQueuedCreatePayload(id, {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (dueDay != null) 'due_day': dueDay,
      });
    } else {
      await _db.enqueueOperation(PendingOperationsCompanion.insert(
        opType: 'update_bill',
        entityType: 'fixed_bill',
        entityId: id,
        payloadJson: jsonEncode({
          if (name != null) 'name': name,
          if (amount != null) 'amount': amount,
          if (dueDay != null) 'due_day': dueDay,
        }),
      ));
    }

    await _trySyncNow();
    return true;
  }

  /// Toggles paid/unpaid. NOTE: if the bill was created offline and hasn't
  /// synced yet, this only flips the local flag and the queued create
  /// payload — it can't deduct the wallet balance or create a linked
  /// ledger expense (those only happen via the real /pay endpoint, which
  /// requires a bill that already exists on the server). That reconciles
  /// itself once the create syncs and the user pays it again normally if
  /// needed. This is a known, accepted limitation for a rare edge case.
  Future<bool> toggleBillPaid(FixedBill bill) async {
    final existing =
        await (_db.select(_db.localFixedBills)..where((b) => b.id.equals(bill.id)))
            .getSingleOrNull();
    if (existing == null) return false;

    final newPaidState = !existing.isPaidCurrentCycle;

    await (_db.update(_db.localFixedBills)..where((b) => b.id.equals(bill.id))).write(
      LocalFixedBillsCompanion(
        isPaidCurrentCycle: Value(newPaidState),
        dirty: const Value(true),
      ),
    );

    if (existing.pendingCreate) {
      await _mergeIntoQueuedCreatePayload(bill.id, {'is_paid_current_cycle': newPaidState});
      await _trySyncNow();
      return true;
    }

    await _db.enqueueOperation(PendingOperationsCompanion.insert(
      opType: newPaidState ? 'pay_bill' : 'unpay_bill',
      entityType: 'fixed_bill',
      entityId: bill.id,
      payloadJson: '{}',
    ));

    await _trySyncNow();
    return true;
  }

  Future<bool> deleteFixedBill(String id) async {
    final existing =
        await (_db.select(_db.localFixedBills)..where((b) => b.id.equals(id))).getSingleOrNull();
    if (existing == null) return false;

    if (existing.pendingCreate) {
      await _removeQueuedOpsFor(id);
      await _db.deleteFixedBillLocally(id);
      return true;
    }

    await (_db.update(_db.localFixedBills)..where((b) => b.id.equals(id)))
        .write(const LocalFixedBillsCompanion(pendingDelete: Value(true), dirty: Value(true)));

    await _db.enqueueOperation(PendingOperationsCompanion.insert(
      opType: 'delete_bill',
      entityType: 'fixed_bill',
      entityId: id,
      payloadJson: '{}',
    ));

    await _trySyncNow();
    return true;
  }

  // ---- helpers ----

  Future<void> _trySyncNow() async {
    if (await _connectivity.isOnlineNow) {
      // Fire and forget — SyncService (driven by connectivity changes) also
      // covers this, but we don't want the UI waiting on network latency
      // for what's already been applied locally and shown.
      await drainQueueOnce();
    }
  }

  Future<void> _removeQueuedOpsFor(String entityId) async {
    final ops = await _db.getPendingOperations();
    for (final op in ops.where((o) => o.entityId == entityId)) {
      await _db.removeOperation(op.id);
    }
  }

  Future<void> _mergeIntoQueuedCreatePayload(String entityId, Map<String, dynamic> patch) async {
    final ops = await _db.getPendingOperations();
    final createOp = ops.where((o) => o.entityId == entityId && o.opType.startsWith('create_'));
    if (createOp.isEmpty) return;
    final op = createOp.first;
    final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
    payload.addAll(patch);
    await _db.removeOperation(op.id);
    await _db.enqueueOperation(PendingOperationsCompanion.insert(
      opType: op.opType,
      entityType: op.entityType,
      entityId: op.entityId,
      payloadJson: jsonEncode(payload),
    ));
  }

  /// Drains one queued operation at a time, in order, stopping on the first
  /// failure so ordering is preserved for retry. Public so SyncService (and
  /// the connectivity-change listener) can trigger it directly.
  Future<void> drainQueueOnce() async {
    while (true) {
      final ops = await _db.getPendingOperations();
      if (ops.isEmpty) break;
      final op = ops.first;

      try {
        await _applyOperation(op);
        await _db.removeOperation(op.id);
      } on ApiException {
        break; // network/server issue — retry on the next trigger
      }
    }
    await refreshFromServer();
  }

  Future<void> _applyOperation(PendingOperation op) async {
    final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;

    switch (op.opType) {
      case 'create_expense':
        final json = await _api.post('/expenses/', {
          'amount': payload['amount'],
          'category': payload['category'],
          'description': payload['description'],
        });
        final created = Expense.fromJson(json);
        await _db.deleteExpenseLocally(op.entityId);
        await _db.upsertExpense(_expenseToCompanion(created, currentUserId!));
        break;

      case 'delete_expense':
        await _api.delete('/expenses/${op.entityId}');
        await _db.deleteExpenseLocally(op.entityId);
        break;

      case 'create_bill':
        final json = await _api.post('/expenses/fixed-bills', {
          'name': payload['name'],
          'amount': payload['amount'],
          'due_day': payload['due_day'],
          'is_paid_current_cycle': payload['is_paid_current_cycle'] ?? false,
        });
        final created = FixedBill.fromJson(json);
        await _db.deleteFixedBillLocally(op.entityId);
        await _db.upsertFixedBill(_billToCompanion(created, currentUserId!));
        break;

      case 'update_bill':
        final json = await _api.patch('/expenses/fixed-bills/${op.entityId}', payload);
        final updated = FixedBill.fromJson(json);
        await _db.upsertFixedBill(_billToCompanion(updated, currentUserId!));
        break;

      case 'pay_bill':
        final json = await _api.post('/expenses/fixed-bills/${op.entityId}/pay', {});
        final updated = FixedBill.fromJson(json);
        await _db.upsertFixedBill(_billToCompanion(updated, currentUserId!));
        break;

      case 'unpay_bill':
        final json = await _api.post('/expenses/fixed-bills/${op.entityId}/unpay', {});
        final updated = FixedBill.fromJson(json);
        await _db.upsertFixedBill(_billToCompanion(updated, currentUserId!));
        break;

      case 'delete_bill':
        await _api.delete('/expenses/fixed-bills/${op.entityId}');
        await _db.deleteFixedBillLocally(op.entityId);
        break;
    }
  }

  // ---- mapping helpers ----

  Expense _expenseFromLocal(LocalExpense row) => Expense(
        id: row.id,
        amount: row.amount,
        category: ExpenseCategoryX.fromApiValue(row.category),
        description: row.description,
        occurredAt: row.occurredAt,
      );

  LocalExpensesCompanion _expenseToCompanion(Expense e, String userId) =>
      LocalExpensesCompanion.insert(
        id: e.id,
        userId: userId,
        amount: e.amount,
        category: e.category.apiValue,
        description: Value(e.description),
        occurredAt: e.occurredAt,
        dirty: const Value(false),
        pendingCreate: const Value(false),
      );

  FixedBill _billFromLocal(LocalFixedBill row) => FixedBill(
        id: row.id,
        name: row.name,
        amount: row.amount,
        dueDay: row.dueDay,
        isPaidCurrentCycle: row.isPaidCurrentCycle,
      );

  LocalFixedBillsCompanion _billToCompanion(FixedBill b, String userId) =>
      LocalFixedBillsCompanion.insert(
        id: b.id,
        userId: userId,
        name: b.name,
        amount: b.amount,
        dueDay: b.dueDay,
        isPaidCurrentCycle: Value(b.isPaidCurrentCycle),
        dirty: const Value(false),
        pendingCreate: const Value(false),
      );
}