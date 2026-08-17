// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyIncomeMeta = const VerificationMeta(
    'monthlyIncome',
  );
  @override
  late final GeneratedColumn<double> monthlyIncome = GeneratedColumn<double>(
    'monthly_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSavingsFloorMeta =
      const VerificationMeta('targetSavingsFloor');
  @override
  late final GeneratedColumn<double> targetSavingsFloor =
      GeneratedColumn<double>(
        'target_savings_floor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _currentWalletBalanceMeta =
      const VerificationMeta('currentWalletBalance');
  @override
  late final GeneratedColumn<double> currentWalletBalance =
      GeneratedColumn<double>(
        'current_wallet_balance',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    fullName,
    monthlyIncome,
    targetSavingsFloor,
    currentWalletBalance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('monthly_income')) {
      context.handle(
        _monthlyIncomeMeta,
        monthlyIncome.isAcceptableOrUnknown(
          data['monthly_income']!,
          _monthlyIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyIncomeMeta);
    }
    if (data.containsKey('target_savings_floor')) {
      context.handle(
        _targetSavingsFloorMeta,
        targetSavingsFloor.isAcceptableOrUnknown(
          data['target_savings_floor']!,
          _targetSavingsFloorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetSavingsFloorMeta);
    }
    if (data.containsKey('current_wallet_balance')) {
      context.handle(
        _currentWalletBalanceMeta,
        currentWalletBalance.isAcceptableOrUnknown(
          data['current_wallet_balance']!,
          _currentWalletBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentWalletBalanceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      monthlyIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_income'],
      )!,
      targetSavingsFloor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_savings_floor'],
      )!,
      currentWalletBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_wallet_balance'],
      )!,
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String id;
  final String email;
  final String fullName;
  final double monthlyIncome;
  final double targetSavingsFloor;
  final double currentWalletBalance;
  const LocalUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.monthlyIncome,
    required this.targetSavingsFloor,
    required this.currentWalletBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['full_name'] = Variable<String>(fullName);
    map['monthly_income'] = Variable<double>(monthlyIncome);
    map['target_savings_floor'] = Variable<double>(targetSavingsFloor);
    map['current_wallet_balance'] = Variable<double>(currentWalletBalance);
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      email: Value(email),
      fullName: Value(fullName),
      monthlyIncome: Value(monthlyIncome),
      targetSavingsFloor: Value(targetSavingsFloor),
      currentWalletBalance: Value(currentWalletBalance),
    );
  }

  factory LocalUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      fullName: serializer.fromJson<String>(json['fullName']),
      monthlyIncome: serializer.fromJson<double>(json['monthlyIncome']),
      targetSavingsFloor: serializer.fromJson<double>(
        json['targetSavingsFloor'],
      ),
      currentWalletBalance: serializer.fromJson<double>(
        json['currentWalletBalance'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'fullName': serializer.toJson<String>(fullName),
      'monthlyIncome': serializer.toJson<double>(monthlyIncome),
      'targetSavingsFloor': serializer.toJson<double>(targetSavingsFloor),
      'currentWalletBalance': serializer.toJson<double>(currentWalletBalance),
    };
  }

  LocalUser copyWith({
    String? id,
    String? email,
    String? fullName,
    double? monthlyIncome,
    double? targetSavingsFloor,
    double? currentWalletBalance,
  }) => LocalUser(
    id: id ?? this.id,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    monthlyIncome: monthlyIncome ?? this.monthlyIncome,
    targetSavingsFloor: targetSavingsFloor ?? this.targetSavingsFloor,
    currentWalletBalance: currentWalletBalance ?? this.currentWalletBalance,
  );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      monthlyIncome: data.monthlyIncome.present
          ? data.monthlyIncome.value
          : this.monthlyIncome,
      targetSavingsFloor: data.targetSavingsFloor.present
          ? data.targetSavingsFloor.value
          : this.targetSavingsFloor,
      currentWalletBalance: data.currentWalletBalance.present
          ? data.currentWalletBalance.value
          : this.currentWalletBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('monthlyIncome: $monthlyIncome, ')
          ..write('targetSavingsFloor: $targetSavingsFloor, ')
          ..write('currentWalletBalance: $currentWalletBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    fullName,
    monthlyIncome,
    targetSavingsFloor,
    currentWalletBalance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.id == this.id &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.monthlyIncome == this.monthlyIncome &&
          other.targetSavingsFloor == this.targetSavingsFloor &&
          other.currentWalletBalance == this.currentWalletBalance);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> fullName;
  final Value<double> monthlyIncome;
  final Value<double> targetSavingsFloor;
  final Value<double> currentWalletBalance;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.monthlyIncome = const Value.absent(),
    this.targetSavingsFloor = const Value.absent(),
    this.currentWalletBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    required String email,
    required String fullName,
    required double monthlyIncome,
    required double targetSavingsFloor,
    required double currentWalletBalance,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       fullName = Value(fullName),
       monthlyIncome = Value(monthlyIncome),
       targetSavingsFloor = Value(targetSavingsFloor),
       currentWalletBalance = Value(currentWalletBalance);
  static Insertable<LocalUser> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<double>? monthlyIncome,
    Expression<double>? targetSavingsFloor,
    Expression<double>? currentWalletBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (monthlyIncome != null) 'monthly_income': monthlyIncome,
      if (targetSavingsFloor != null)
        'target_savings_floor': targetSavingsFloor,
      if (currentWalletBalance != null)
        'current_wallet_balance': currentWalletBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? fullName,
    Value<double>? monthlyIncome,
    Value<double>? targetSavingsFloor,
    Value<double>? currentWalletBalance,
    Value<int>? rowid,
  }) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      targetSavingsFloor: targetSavingsFloor ?? this.targetSavingsFloor,
      currentWalletBalance: currentWalletBalance ?? this.currentWalletBalance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (monthlyIncome.present) {
      map['monthly_income'] = Variable<double>(monthlyIncome.value);
    }
    if (targetSavingsFloor.present) {
      map['target_savings_floor'] = Variable<double>(targetSavingsFloor.value);
    }
    if (currentWalletBalance.present) {
      map['current_wallet_balance'] = Variable<double>(
        currentWalletBalance.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('monthlyIncome: $monthlyIncome, ')
          ..write('targetSavingsFloor: $targetSavingsFloor, ')
          ..write('currentWalletBalance: $currentWalletBalance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFixedBillsTable extends LocalFixedBills
    with TableInfo<$LocalFixedBillsTable, LocalFixedBill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFixedBillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPaidCurrentCycleMeta =
      const VerificationMeta('isPaidCurrentCycle');
  @override
  late final GeneratedColumn<bool> isPaidCurrentCycle = GeneratedColumn<bool>(
    'is_paid_current_cycle',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paid_current_cycle" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingCreateMeta = const VerificationMeta(
    'pendingCreate',
  );
  @override
  late final GeneratedColumn<bool> pendingCreate = GeneratedColumn<bool>(
    'pending_create',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_create" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingDeleteMeta = const VerificationMeta(
    'pendingDelete',
  );
  @override
  late final GeneratedColumn<bool> pendingDelete = GeneratedColumn<bool>(
    'pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    amount,
    dueDay,
    isPaidCurrentCycle,
    dirty,
    pendingCreate,
    pendingDelete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_fixed_bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFixedBill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDayMeta);
    }
    if (data.containsKey('is_paid_current_cycle')) {
      context.handle(
        _isPaidCurrentCycleMeta,
        isPaidCurrentCycle.isAcceptableOrUnknown(
          data['is_paid_current_cycle']!,
          _isPaidCurrentCycleMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('pending_create')) {
      context.handle(
        _pendingCreateMeta,
        pendingCreate.isAcceptableOrUnknown(
          data['pending_create']!,
          _pendingCreateMeta,
        ),
      );
    }
    if (data.containsKey('pending_delete')) {
      context.handle(
        _pendingDeleteMeta,
        pendingDelete.isAcceptableOrUnknown(
          data['pending_delete']!,
          _pendingDeleteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFixedBill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFixedBill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      )!,
      isPaidCurrentCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paid_current_cycle'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      pendingCreate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_create'],
      )!,
      pendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_delete'],
      )!,
    );
  }

  @override
  $LocalFixedBillsTable createAlias(String alias) {
    return $LocalFixedBillsTable(attachedDatabase, alias);
  }
}

class LocalFixedBill extends DataClass implements Insertable<LocalFixedBill> {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final int dueDay;
  final bool isPaidCurrentCycle;
  final bool dirty;
  final bool pendingCreate;
  final bool pendingDelete;
  const LocalFixedBill({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.isPaidCurrentCycle,
    required this.dirty,
    required this.pendingCreate,
    required this.pendingDelete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['due_day'] = Variable<int>(dueDay);
    map['is_paid_current_cycle'] = Variable<bool>(isPaidCurrentCycle);
    map['dirty'] = Variable<bool>(dirty);
    map['pending_create'] = Variable<bool>(pendingCreate);
    map['pending_delete'] = Variable<bool>(pendingDelete);
    return map;
  }

  LocalFixedBillsCompanion toCompanion(bool nullToAbsent) {
    return LocalFixedBillsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      amount: Value(amount),
      dueDay: Value(dueDay),
      isPaidCurrentCycle: Value(isPaidCurrentCycle),
      dirty: Value(dirty),
      pendingCreate: Value(pendingCreate),
      pendingDelete: Value(pendingDelete),
    );
  }

  factory LocalFixedBill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFixedBill(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      dueDay: serializer.fromJson<int>(json['dueDay']),
      isPaidCurrentCycle: serializer.fromJson<bool>(json['isPaidCurrentCycle']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      pendingCreate: serializer.fromJson<bool>(json['pendingCreate']),
      pendingDelete: serializer.fromJson<bool>(json['pendingDelete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'dueDay': serializer.toJson<int>(dueDay),
      'isPaidCurrentCycle': serializer.toJson<bool>(isPaidCurrentCycle),
      'dirty': serializer.toJson<bool>(dirty),
      'pendingCreate': serializer.toJson<bool>(pendingCreate),
      'pendingDelete': serializer.toJson<bool>(pendingDelete),
    };
  }

  LocalFixedBill copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    int? dueDay,
    bool? isPaidCurrentCycle,
    bool? dirty,
    bool? pendingCreate,
    bool? pendingDelete,
  }) => LocalFixedBill(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    dueDay: dueDay ?? this.dueDay,
    isPaidCurrentCycle: isPaidCurrentCycle ?? this.isPaidCurrentCycle,
    dirty: dirty ?? this.dirty,
    pendingCreate: pendingCreate ?? this.pendingCreate,
    pendingDelete: pendingDelete ?? this.pendingDelete,
  );
  LocalFixedBill copyWithCompanion(LocalFixedBillsCompanion data) {
    return LocalFixedBill(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      isPaidCurrentCycle: data.isPaidCurrentCycle.present
          ? data.isPaidCurrentCycle.value
          : this.isPaidCurrentCycle,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      pendingCreate: data.pendingCreate.present
          ? data.pendingCreate.value
          : this.pendingCreate,
      pendingDelete: data.pendingDelete.present
          ? data.pendingDelete.value
          : this.pendingDelete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFixedBill(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('dueDay: $dueDay, ')
          ..write('isPaidCurrentCycle: $isPaidCurrentCycle, ')
          ..write('dirty: $dirty, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingDelete: $pendingDelete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    amount,
    dueDay,
    isPaidCurrentCycle,
    dirty,
    pendingCreate,
    pendingDelete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFixedBill &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.dueDay == this.dueDay &&
          other.isPaidCurrentCycle == this.isPaidCurrentCycle &&
          other.dirty == this.dirty &&
          other.pendingCreate == this.pendingCreate &&
          other.pendingDelete == this.pendingDelete);
}

class LocalFixedBillsCompanion extends UpdateCompanion<LocalFixedBill> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<double> amount;
  final Value<int> dueDay;
  final Value<bool> isPaidCurrentCycle;
  final Value<bool> dirty;
  final Value<bool> pendingCreate;
  final Value<bool> pendingDelete;
  final Value<int> rowid;
  const LocalFixedBillsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.isPaidCurrentCycle = const Value.absent(),
    this.dirty = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFixedBillsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required double amount,
    required int dueDay,
    this.isPaidCurrentCycle = const Value.absent(),
    this.dirty = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       amount = Value(amount),
       dueDay = Value(dueDay);
  static Insertable<LocalFixedBill> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<int>? dueDay,
    Expression<bool>? isPaidCurrentCycle,
    Expression<bool>? dirty,
    Expression<bool>? pendingCreate,
    Expression<bool>? pendingDelete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (dueDay != null) 'due_day': dueDay,
      if (isPaidCurrentCycle != null)
        'is_paid_current_cycle': isPaidCurrentCycle,
      if (dirty != null) 'dirty': dirty,
      if (pendingCreate != null) 'pending_create': pendingCreate,
      if (pendingDelete != null) 'pending_delete': pendingDelete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFixedBillsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<double>? amount,
    Value<int>? dueDay,
    Value<bool>? isPaidCurrentCycle,
    Value<bool>? dirty,
    Value<bool>? pendingCreate,
    Value<bool>? pendingDelete,
    Value<int>? rowid,
  }) {
    return LocalFixedBillsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      isPaidCurrentCycle: isPaidCurrentCycle ?? this.isPaidCurrentCycle,
      dirty: dirty ?? this.dirty,
      pendingCreate: pendingCreate ?? this.pendingCreate,
      pendingDelete: pendingDelete ?? this.pendingDelete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (isPaidCurrentCycle.present) {
      map['is_paid_current_cycle'] = Variable<bool>(isPaidCurrentCycle.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (pendingCreate.present) {
      map['pending_create'] = Variable<bool>(pendingCreate.value);
    }
    if (pendingDelete.present) {
      map['pending_delete'] = Variable<bool>(pendingDelete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFixedBillsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('dueDay: $dueDay, ')
          ..write('isPaidCurrentCycle: $isPaidCurrentCycle, ')
          ..write('dirty: $dirty, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExpensesTable extends LocalExpenses
    with TableInfo<$LocalExpensesTable, LocalExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedFixedBillIdMeta =
      const VerificationMeta('relatedFixedBillId');
  @override
  late final GeneratedColumn<String> relatedFixedBillId =
      GeneratedColumn<String>(
        'related_fixed_bill_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingCreateMeta = const VerificationMeta(
    'pendingCreate',
  );
  @override
  late final GeneratedColumn<bool> pendingCreate = GeneratedColumn<bool>(
    'pending_create',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_create" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingDeleteMeta = const VerificationMeta(
    'pendingDelete',
  );
  @override
  late final GeneratedColumn<bool> pendingDelete = GeneratedColumn<bool>(
    'pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    amount,
    category,
    description,
    occurredAt,
    relatedFixedBillId,
    dirty,
    pendingCreate,
    pendingDelete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalExpense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('related_fixed_bill_id')) {
      context.handle(
        _relatedFixedBillIdMeta,
        relatedFixedBillId.isAcceptableOrUnknown(
          data['related_fixed_bill_id']!,
          _relatedFixedBillIdMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('pending_create')) {
      context.handle(
        _pendingCreateMeta,
        pendingCreate.isAcceptableOrUnknown(
          data['pending_create']!,
          _pendingCreateMeta,
        ),
      );
    }
    if (data.containsKey('pending_delete')) {
      context.handle(
        _pendingDeleteMeta,
        pendingDelete.isAcceptableOrUnknown(
          data['pending_delete']!,
          _pendingDeleteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExpense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      relatedFixedBillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_fixed_bill_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      pendingCreate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_create'],
      )!,
      pendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_delete'],
      )!,
    );
  }

  @override
  $LocalExpensesTable createAlias(String alias) {
    return $LocalExpensesTable(attachedDatabase, alias);
  }
}

class LocalExpense extends DataClass implements Insertable<LocalExpense> {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String? description;
  final DateTime occurredAt;
  final String? relatedFixedBillId;
  final bool dirty;
  final bool pendingCreate;
  final bool pendingDelete;
  const LocalExpense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    required this.occurredAt,
    this.relatedFixedBillId,
    required this.dirty,
    required this.pendingCreate,
    required this.pendingDelete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || relatedFixedBillId != null) {
      map['related_fixed_bill_id'] = Variable<String>(relatedFixedBillId);
    }
    map['dirty'] = Variable<bool>(dirty);
    map['pending_create'] = Variable<bool>(pendingCreate);
    map['pending_delete'] = Variable<bool>(pendingDelete);
    return map;
  }

  LocalExpensesCompanion toCompanion(bool nullToAbsent) {
    return LocalExpensesCompanion(
      id: Value(id),
      userId: Value(userId),
      amount: Value(amount),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      occurredAt: Value(occurredAt),
      relatedFixedBillId: relatedFixedBillId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedFixedBillId),
      dirty: Value(dirty),
      pendingCreate: Value(pendingCreate),
      pendingDelete: Value(pendingDelete),
    );
  }

  factory LocalExpense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExpense(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      relatedFixedBillId: serializer.fromJson<String?>(
        json['relatedFixedBillId'],
      ),
      dirty: serializer.fromJson<bool>(json['dirty']),
      pendingCreate: serializer.fromJson<bool>(json['pendingCreate']),
      pendingDelete: serializer.fromJson<bool>(json['pendingDelete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String?>(description),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'relatedFixedBillId': serializer.toJson<String?>(relatedFixedBillId),
      'dirty': serializer.toJson<bool>(dirty),
      'pendingCreate': serializer.toJson<bool>(pendingCreate),
      'pendingDelete': serializer.toJson<bool>(pendingDelete),
    };
  }

  LocalExpense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    Value<String?> description = const Value.absent(),
    DateTime? occurredAt,
    Value<String?> relatedFixedBillId = const Value.absent(),
    bool? dirty,
    bool? pendingCreate,
    bool? pendingDelete,
  }) => LocalExpense(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    occurredAt: occurredAt ?? this.occurredAt,
    relatedFixedBillId: relatedFixedBillId.present
        ? relatedFixedBillId.value
        : this.relatedFixedBillId,
    dirty: dirty ?? this.dirty,
    pendingCreate: pendingCreate ?? this.pendingCreate,
    pendingDelete: pendingDelete ?? this.pendingDelete,
  );
  LocalExpense copyWithCompanion(LocalExpensesCompanion data) {
    return LocalExpense(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      relatedFixedBillId: data.relatedFixedBillId.present
          ? data.relatedFixedBillId.value
          : this.relatedFixedBillId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      pendingCreate: data.pendingCreate.present
          ? data.pendingCreate.value
          : this.pendingCreate,
      pendingDelete: data.pendingDelete.present
          ? data.pendingDelete.value
          : this.pendingDelete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpense(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('relatedFixedBillId: $relatedFixedBillId, ')
          ..write('dirty: $dirty, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingDelete: $pendingDelete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    amount,
    category,
    description,
    occurredAt,
    relatedFixedBillId,
    dirty,
    pendingCreate,
    pendingDelete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExpense &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.relatedFixedBillId == this.relatedFixedBillId &&
          other.dirty == this.dirty &&
          other.pendingCreate == this.pendingCreate &&
          other.pendingDelete == this.pendingDelete);
}

class LocalExpensesCompanion extends UpdateCompanion<LocalExpense> {
  final Value<String> id;
  final Value<String> userId;
  final Value<double> amount;
  final Value<String> category;
  final Value<String?> description;
  final Value<DateTime> occurredAt;
  final Value<String?> relatedFixedBillId;
  final Value<bool> dirty;
  final Value<bool> pendingCreate;
  final Value<bool> pendingDelete;
  final Value<int> rowid;
  const LocalExpensesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.relatedFixedBillId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExpensesCompanion.insert({
    required String id,
    required String userId,
    required double amount,
    required String category,
    this.description = const Value.absent(),
    required DateTime occurredAt,
    this.relatedFixedBillId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       amount = Value(amount),
       category = Value(category),
       occurredAt = Value(occurredAt);
  static Insertable<LocalExpense> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? description,
    Expression<DateTime>? occurredAt,
    Expression<String>? relatedFixedBillId,
    Expression<bool>? dirty,
    Expression<bool>? pendingCreate,
    Expression<bool>? pendingDelete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (relatedFixedBillId != null)
        'related_fixed_bill_id': relatedFixedBillId,
      if (dirty != null) 'dirty': dirty,
      if (pendingCreate != null) 'pending_create': pendingCreate,
      if (pendingDelete != null) 'pending_delete': pendingDelete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<double>? amount,
    Value<String>? category,
    Value<String?>? description,
    Value<DateTime>? occurredAt,
    Value<String?>? relatedFixedBillId,
    Value<bool>? dirty,
    Value<bool>? pendingCreate,
    Value<bool>? pendingDelete,
    Value<int>? rowid,
  }) {
    return LocalExpensesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      relatedFixedBillId: relatedFixedBillId ?? this.relatedFixedBillId,
      dirty: dirty ?? this.dirty,
      pendingCreate: pendingCreate ?? this.pendingCreate,
      pendingDelete: pendingDelete ?? this.pendingDelete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (relatedFixedBillId.present) {
      map['related_fixed_bill_id'] = Variable<String>(relatedFixedBillId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (pendingCreate.present) {
      map['pending_create'] = Variable<bool>(pendingCreate.value);
    }
    if (pendingDelete.present) {
      map['pending_delete'] = Variable<bool>(pendingDelete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpensesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('relatedFixedBillId: $relatedFixedBillId, ')
          ..write('dirty: $dirty, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    opType,
    entityType,
    entityId,
    payloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperation extends DataClass
    implements Insertable<PendingOperation> {
  final int id;
  final String opType;
  final String entityType;
  final String entityId;
  final String payloadJson;
  final DateTime createdAt;
  const PendingOperation({
    required this.id,
    required this.opType,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['op_type'] = Variable<String>(opType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      opType: Value(opType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory PendingOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperation(
      id: serializer.fromJson<int>(json['id']),
      opType: serializer.fromJson<String>(json['opType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'opType': serializer.toJson<String>(opType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingOperation copyWith({
    int? id,
    String? opType,
    String? entityType,
    String? entityId,
    String? payloadJson,
    DateTime? createdAt,
  }) => PendingOperation(
    id: id ?? this.id,
    opType: opType ?? this.opType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingOperation copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperation(
      id: data.id.present ? data.id.value : this.id,
      opType: data.opType.present ? data.opType.value : this.opType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperation(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, opType, entityType, entityId, payloadJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperation &&
          other.id == this.id &&
          other.opType == this.opType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperation> {
  final Value<int> id;
  final Value<String> opType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.opType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String opType,
    required String entityType,
    required String entityId,
    required String payloadJson,
    this.createdAt = const Value.absent(),
  }) : opType = Value(opType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       payloadJson = Value(payloadJson);
  static Insertable<PendingOperation> custom({
    Expression<int>? id,
    Expression<String>? opType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opType != null) 'op_type': opType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<int>? id,
    Value<String>? opType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
  }) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $LocalFixedBillsTable localFixedBills = $LocalFixedBillsTable(
    this,
  );
  late final $LocalExpensesTable localExpenses = $LocalExpensesTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUsers,
    localFixedBills,
    localExpenses,
    pendingOperations,
  ];
}

typedef $$LocalUsersTableCreateCompanionBuilder =
    LocalUsersCompanion Function({
      required String id,
      required String email,
      required String fullName,
      required double monthlyIncome,
      required double targetSavingsFloor,
      required double currentWalletBalance,
      Value<int> rowid,
    });
typedef $$LocalUsersTableUpdateCompanionBuilder =
    LocalUsersCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> fullName,
      Value<double> monthlyIncome,
      Value<double> targetSavingsFloor,
      Value<double> currentWalletBalance,
      Value<int> rowid,
    });

class $$LocalUsersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyIncome => $composableBuilder(
    column: $table.monthlyIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetSavingsFloor => $composableBuilder(
    column: $table.targetSavingsFloor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentWalletBalance => $composableBuilder(
    column: $table.currentWalletBalance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyIncome => $composableBuilder(
    column: $table.monthlyIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetSavingsFloor => $composableBuilder(
    column: $table.targetSavingsFloor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentWalletBalance => $composableBuilder(
    column: $table.currentWalletBalance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<double> get monthlyIncome => $composableBuilder(
    column: $table.monthlyIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetSavingsFloor => $composableBuilder(
    column: $table.targetSavingsFloor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentWalletBalance => $composableBuilder(
    column: $table.currentWalletBalance,
    builder: (column) => column,
  );
}

class $$LocalUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUsersTable,
          LocalUser,
          $$LocalUsersTableFilterComposer,
          $$LocalUsersTableOrderingComposer,
          $$LocalUsersTableAnnotationComposer,
          $$LocalUsersTableCreateCompanionBuilder,
          $$LocalUsersTableUpdateCompanionBuilder,
          (
            LocalUser,
            BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>,
          ),
          LocalUser,
          PrefetchHooks Function()
        > {
  $$LocalUsersTableTableManager(_$AppDatabase db, $LocalUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<double> monthlyIncome = const Value.absent(),
                Value<double> targetSavingsFloor = const Value.absent(),
                Value<double> currentWalletBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion(
                id: id,
                email: email,
                fullName: fullName,
                monthlyIncome: monthlyIncome,
                targetSavingsFloor: targetSavingsFloor,
                currentWalletBalance: currentWalletBalance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String fullName,
                required double monthlyIncome,
                required double targetSavingsFloor,
                required double currentWalletBalance,
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion.insert(
                id: id,
                email: email,
                fullName: fullName,
                monthlyIncome: monthlyIncome,
                targetSavingsFloor: targetSavingsFloor,
                currentWalletBalance: currentWalletBalance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUsersTable,
      LocalUser,
      $$LocalUsersTableFilterComposer,
      $$LocalUsersTableOrderingComposer,
      $$LocalUsersTableAnnotationComposer,
      $$LocalUsersTableCreateCompanionBuilder,
      $$LocalUsersTableUpdateCompanionBuilder,
      (LocalUser, BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>),
      LocalUser,
      PrefetchHooks Function()
    >;
typedef $$LocalFixedBillsTableCreateCompanionBuilder =
    LocalFixedBillsCompanion Function({
      required String id,
      required String userId,
      required String name,
      required double amount,
      required int dueDay,
      Value<bool> isPaidCurrentCycle,
      Value<bool> dirty,
      Value<bool> pendingCreate,
      Value<bool> pendingDelete,
      Value<int> rowid,
    });
typedef $$LocalFixedBillsTableUpdateCompanionBuilder =
    LocalFixedBillsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<double> amount,
      Value<int> dueDay,
      Value<bool> isPaidCurrentCycle,
      Value<bool> dirty,
      Value<bool> pendingCreate,
      Value<bool> pendingDelete,
      Value<int> rowid,
    });

class $$LocalFixedBillsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFixedBillsTable> {
  $$LocalFixedBillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaidCurrentCycle => $composableBuilder(
    column: $table.isPaidCurrentCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalFixedBillsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFixedBillsTable> {
  $$LocalFixedBillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaidCurrentCycle => $composableBuilder(
    column: $table.isPaidCurrentCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalFixedBillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFixedBillsTable> {
  $$LocalFixedBillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<bool> get isPaidCurrentCycle => $composableBuilder(
    column: $table.isPaidCurrentCycle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => column,
  );
}

class $$LocalFixedBillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFixedBillsTable,
          LocalFixedBill,
          $$LocalFixedBillsTableFilterComposer,
          $$LocalFixedBillsTableOrderingComposer,
          $$LocalFixedBillsTableAnnotationComposer,
          $$LocalFixedBillsTableCreateCompanionBuilder,
          $$LocalFixedBillsTableUpdateCompanionBuilder,
          (
            LocalFixedBill,
            BaseReferences<
              _$AppDatabase,
              $LocalFixedBillsTable,
              LocalFixedBill
            >,
          ),
          LocalFixedBill,
          PrefetchHooks Function()
        > {
  $$LocalFixedBillsTableTableManager(
    _$AppDatabase db,
    $LocalFixedBillsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFixedBillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFixedBillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFixedBillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> dueDay = const Value.absent(),
                Value<bool> isPaidCurrentCycle = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFixedBillsCompanion(
                id: id,
                userId: userId,
                name: name,
                amount: amount,
                dueDay: dueDay,
                isPaidCurrentCycle: isPaidCurrentCycle,
                dirty: dirty,
                pendingCreate: pendingCreate,
                pendingDelete: pendingDelete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required double amount,
                required int dueDay,
                Value<bool> isPaidCurrentCycle = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFixedBillsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                amount: amount,
                dueDay: dueDay,
                isPaidCurrentCycle: isPaidCurrentCycle,
                dirty: dirty,
                pendingCreate: pendingCreate,
                pendingDelete: pendingDelete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFixedBillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFixedBillsTable,
      LocalFixedBill,
      $$LocalFixedBillsTableFilterComposer,
      $$LocalFixedBillsTableOrderingComposer,
      $$LocalFixedBillsTableAnnotationComposer,
      $$LocalFixedBillsTableCreateCompanionBuilder,
      $$LocalFixedBillsTableUpdateCompanionBuilder,
      (
        LocalFixedBill,
        BaseReferences<_$AppDatabase, $LocalFixedBillsTable, LocalFixedBill>,
      ),
      LocalFixedBill,
      PrefetchHooks Function()
    >;
typedef $$LocalExpensesTableCreateCompanionBuilder =
    LocalExpensesCompanion Function({
      required String id,
      required String userId,
      required double amount,
      required String category,
      Value<String?> description,
      required DateTime occurredAt,
      Value<String?> relatedFixedBillId,
      Value<bool> dirty,
      Value<bool> pendingCreate,
      Value<bool> pendingDelete,
      Value<int> rowid,
    });
typedef $$LocalExpensesTableUpdateCompanionBuilder =
    LocalExpensesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<double> amount,
      Value<String> category,
      Value<String?> description,
      Value<DateTime> occurredAt,
      Value<String?> relatedFixedBillId,
      Value<bool> dirty,
      Value<bool> pendingCreate,
      Value<bool> pendingDelete,
      Value<int> rowid,
    });

class $$LocalExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedFixedBillId => $composableBuilder(
    column: $table.relatedFixedBillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedFixedBillId => $composableBuilder(
    column: $table.relatedFixedBillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedFixedBillId => $composableBuilder(
    column: $table.relatedFixedBillId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => column,
  );
}

class $$LocalExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExpensesTable,
          LocalExpense,
          $$LocalExpensesTableFilterComposer,
          $$LocalExpensesTableOrderingComposer,
          $$LocalExpensesTableAnnotationComposer,
          $$LocalExpensesTableCreateCompanionBuilder,
          $$LocalExpensesTableUpdateCompanionBuilder,
          (
            LocalExpense,
            BaseReferences<_$AppDatabase, $LocalExpensesTable, LocalExpense>,
          ),
          LocalExpense,
          PrefetchHooks Function()
        > {
  $$LocalExpensesTableTableManager(_$AppDatabase db, $LocalExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> relatedFixedBillId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpensesCompanion(
                id: id,
                userId: userId,
                amount: amount,
                category: category,
                description: description,
                occurredAt: occurredAt,
                relatedFixedBillId: relatedFixedBillId,
                dirty: dirty,
                pendingCreate: pendingCreate,
                pendingDelete: pendingDelete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required double amount,
                required String category,
                Value<String?> description = const Value.absent(),
                required DateTime occurredAt,
                Value<String?> relatedFixedBillId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpensesCompanion.insert(
                id: id,
                userId: userId,
                amount: amount,
                category: category,
                description: description,
                occurredAt: occurredAt,
                relatedFixedBillId: relatedFixedBillId,
                dirty: dirty,
                pendingCreate: pendingCreate,
                pendingDelete: pendingDelete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExpensesTable,
      LocalExpense,
      $$LocalExpensesTableFilterComposer,
      $$LocalExpensesTableOrderingComposer,
      $$LocalExpensesTableAnnotationComposer,
      $$LocalExpensesTableCreateCompanionBuilder,
      $$LocalExpensesTableUpdateCompanionBuilder,
      (
        LocalExpense,
        BaseReferences<_$AppDatabase, $LocalExpensesTable, LocalExpense>,
      ),
      LocalExpense,
      PrefetchHooks Function()
    >;
typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      required String opType,
      required String entityType,
      required String entityId,
      required String payloadJson,
      Value<DateTime> createdAt,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      Value<String> opType,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTable,
              PendingOperation
            >,
          ),
          PendingOperation,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingOperationsCompanion(
                id: id,
                opType: opType,
                entityType: entityType,
                entityId: entityId,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String opType,
                required String entityType,
                required String entityId,
                required String payloadJson,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                id: id,
                opType: opType,
                entityType: entityType,
                entityId: entityId,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperation,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation
        >,
      ),
      PendingOperation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$LocalFixedBillsTableTableManager get localFixedBills =>
      $$LocalFixedBillsTableTableManager(_db, _db.localFixedBills);
  $$LocalExpensesTableTableManager get localExpenses =>
      $$LocalExpensesTableTableManager(_db, _db.localExpenses);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
}
