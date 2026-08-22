import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../../expenses/data/expense_repository.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  // Optional so this class stays usable/testable without dragging in the
  // whole offline stack; main.dart always supplies it in the real app.
  final ExpenseRepository? _expenseRepository;

  bool isLoggedIn = false;
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  AuthProvider(this._repository, {ExpenseRepository? expenseRepository})
      : _expenseRepository = expenseRepository;

  Future<void> _fetchUser() async {
    try {
      currentUser = await _repository.getCurrentUser();
      _expenseRepository?.currentUserId = currentUser?.id;
    } on ApiException {
      // Offline or server hiccup. If we already had a user loaded, keep
      // showing their last-known data instead of blanking the dashboard —
      // local wallet-balance changes from offline bill payments still need
      // to be visible even though we can't confirm them with the server
      // right now. Only clear currentUser if we never had one (e.g. token
      // is actually invalid, caught separately via onUnauthorized).
      if (currentUser == null) {
        _expenseRepository?.currentUserId = null;
      }
    }
  }

  Future<bool> login(String email, String pin) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.login(email: email, pin: pin);
      isLoggedIn = true;
      await _fetchUser();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String pin,
    required String fullName,
    required double monthlyIncome,
    required double targetSavingsFloor,
    required double currentWalletBalance,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.register(
        email: email,
        pin: pin,
        fullName: fullName,
        monthlyIncome: monthlyIncome,
        targetSavingsFloor: targetSavingsFloor,
        currentWalletBalance: currentWalletBalance,
      );
      // Auto-login right after successful registration
      await _repository.login(email: email, pin: pin);
      isLoggedIn = true;
      await _fetchUser();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    isLoggedIn = false;
    currentUser = null;
    _expenseRepository?.currentUserId = null;
    notifyListeners();
  }

  /// Called when a request comes back 401 - the token is already invalid,
  /// so just clear local state instead of attempting another API call.
  void forceLogout() {
    _repository.logout(); // clears stored token, fire-and-forget
    isLoggedIn = false;
    currentUser = null;
    _expenseRepository?.currentUserId = null;
    errorMessage = 'Your session expired. Please log in again.';
    notifyListeners();
  }

  Future<void> checkLoginState() async {
    isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) await _fetchUser();
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    await _fetchUser();
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName,
    double? monthlyIncome,
    double? targetSavingsFloor,
    double? currentWalletBalance,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _repository.updateProfile(
        fullName: fullName,
        monthlyIncome: monthlyIncome,
        targetSavingsFloor: targetSavingsFloor,
        currentWalletBalance: currentWalletBalance,
      );
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
