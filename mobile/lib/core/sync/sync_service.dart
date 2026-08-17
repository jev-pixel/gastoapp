import 'dart:async';

import '../../features/expenses/data/expense_repository.dart';
import '../connectivity_service.dart';

/// Watches connectivity and drains the offline write queue whenever the
/// device transitions from offline to online. Silent — no UI signal, per
/// design; sync just happens in the background.
class SyncService {
  final ExpenseRepository _expenseRepository;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _subscription;
  bool _wasOnline = true;

  SyncService(this._expenseRepository, this._connectivity);

  void start() {
    _subscription = _connectivity.onStatusChange.listen((isOnline) {
      if (isOnline && !_wasOnline) {
        // Just came back online — flush whatever queued up while offline.
        _expenseRepository.drainQueueOnce();
      }
      _wasOnline = isOnline;
    });

    // Also do one drain attempt at startup, in case there were leftover
    // queued operations from a previous session that never got a chance
    // to sync (e.g. app was killed while offline).
    _expenseRepository.drainQueueOnce();
  }

  void dispose() {
    _subscription?.cancel();
  }
}