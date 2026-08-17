import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

// ---- Tables ----
// These mirror the backend's SQLAlchemy models (see backend/app/db/models/).
// IDs are stored as TEXT because the backend uses UUIDs.

class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  RealColumn get monthlyIncome => real()();
  RealColumn get targetSavingsFloor => real()();
  RealColumn get currentWalletBalance => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalFixedBills extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  IntColumn get dueDay => integer()();
  BoolColumn get isPaidCurrentCycle => boolean().withDefault(const Constant(false))();
  // True when this row has local changes not yet confirmed by the server.
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  // True when this row was created offline and doesn't have a real
  // server-issued UUID yet (a temporary client-generated id is used instead).
  BoolColumn get pendingCreate => boolean().withDefault(const Constant(false))();
  // True when the user deleted this row while offline; hidden from the UI
  // but kept until the delete syncs, so we can still cancel/undo cleanly.
  BoolColumn get pendingDelete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()(); // 'essential' | 'wants' | 'fixed_due'
  TextColumn get description => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get relatedFixedBillId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingCreate => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingDelete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// The sync queue. Every offline mutation (create/pay/unpay/delete/update)
// gets recorded here, in order, and drained by the sync worker once the
// device is back online. entityId lets us find the affected local row;
// payloadJson carries whatever the API call needs (e.g. amount, category).
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [LocalUsers, LocalFixedBills, LocalExpenses, PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this and add a migration step in `migration` whenever a table
  // shape changes — Drift will not auto-detect schema changes for you.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );

  // ---- Users ----

  Future<void> upsertUser(LocalUsersCompanion user) =>
      into(localUsers).insertOnConflictUpdate(user);

  Future<LocalUser?> getUser(String id) =>
      (select(localUsers)..where((u) => u.id.equals(id))).getSingleOrNull();

  Stream<LocalUser?> watchUser(String id) =>
      (select(localUsers)..where((u) => u.id.equals(id))).watchSingleOrNull();

  // ---- Fixed Bills ----

  Future<void> upsertFixedBill(LocalFixedBillsCompanion bill) =>
      into(localFixedBills).insertOnConflictUpdate(bill);

  Stream<List<LocalFixedBill>> watchFixedBills(String userId) {
    return (select(localFixedBills)
          ..where((b) => b.userId.equals(userId) & b.pendingDelete.equals(false))
          ..orderBy([(b) => OrderingTerm.asc(b.dueDay)]))
        .watch();
  }

  Future<void> deleteFixedBillLocally(String id) =>
      (delete(localFixedBills)..where((b) => b.id.equals(id))).go();

  // ---- Expenses ----

  Future<void> upsertExpense(LocalExpensesCompanion expense) =>
      into(localExpenses).insertOnConflictUpdate(expense);

  Stream<List<LocalExpense>> watchExpenses(String userId) {
    return (select(localExpenses)
          ..where((e) => e.userId.equals(userId) & e.pendingDelete.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]))
        .watch();
  }

  Future<void> deleteExpenseLocally(String id) =>
      (delete(localExpenses)..where((e) => e.id.equals(id))).go();

  // ---- Sync Queue ----

  Future<int> enqueueOperation(PendingOperationsCompanion op) =>
      into(pendingOperations).insert(op);

  Future<List<PendingOperation>> getPendingOperations() =>
      (select(pendingOperations)..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();

  Future<void> removeOperation(int id) =>
      (delete(pendingOperations)..where((o) => o.id.equals(id))).go();

  Stream<int> watchPendingCount() =>
      pendingOperations.count().watchSingle();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gastoapp.sqlite'));

    // Required on Android/iOS so sqlite3 native libs are bundled correctly.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}