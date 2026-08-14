import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  bool isLoggedIn = false;
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  AuthProvider(this._repository);

  Future<void> _fetchUser() async {
    try {
      currentUser = await _repository.getCurrentUser();
    } on ApiException {
      currentUser = null;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.login(email: email, password: password);
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
    required String password,
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
        password: password,
        fullName: fullName,
        monthlyIncome: monthlyIncome,
        targetSavingsFloor: targetSavingsFloor,
        currentWalletBalance: currentWalletBalance,
      );
      // Auto-login right after successful registration
      await _repository.login(email: email, password: password);
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
    notifyListeners();
  }

  /// Called when a request comes back 401 - the token is already invalid,
  /// so just clear local state instead of attempting another API call.
  void forceLogout() {
    _repository.logout(); // clears stored token, fire-and-forget
    isLoggedIn = false;
    currentUser = null;
    errorMessage = 'Your session expired. Please log in again.';
    notifyListeners();
  }

  Future<void> checkLoginState() async {
    isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) await _fetchUser();
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

Future<void> refreshCurrentUser() async {
  await _fetchUser();
  notifyListeners();
}

}