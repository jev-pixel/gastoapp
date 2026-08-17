import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus that collapses its detailed
/// connection-type results down to a simple online/offline signal, which is
/// all the repository/sync layer actually needs to make decisions.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Emits true whenever the device has *some* network path (wifi, mobile
  /// data, ethernet), false when it has none. Does not guarantee the
  /// network path can actually reach the internet (e.g. a wifi network
  /// with no upstream) — that distinction isn't worth the extra complexity
  /// here, since a failed API call will still fall back to queuing.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  Future<bool> get isOnlineNow async => _isOnline(await _connectivity.checkConnectivity());

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}