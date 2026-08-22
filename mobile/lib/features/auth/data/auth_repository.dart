import '../../../core/api_client.dart';
import '../../../core/token_storage.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthRepository(this._api, this._tokenStorage);

  Future<User> register({
    required String email,
    required String pin,
    required String fullName,
    double monthlyIncome = 0,
    double targetSavingsFloor = 0,
    double currentWalletBalance = 0,
  }) async {
    final json = await _api.post('/auth/register', {
      'email': email,
      // Wire format key stays 'password' to match the backend schema —
      // only the client-side terminology changed to PIN.
      'password': pin,
      'full_name': fullName,
      'monthly_income': monthlyIncome,
      'target_savings_floor': targetSavingsFloor,
      'current_wallet_balance': currentWalletBalance,
    }, auth: false);
    return User.fromJson(json);
  }

  Future<void> login({required String email, required String pin}) async {
    final json = await _api.post('/auth/login', {
      'email': email,
      'password': pin,
    }, auth: false);
    await _tokenStorage.saveToken(json['access_token'] as String);
  }

  Future<void> logout() => _tokenStorage.clearToken();

  Future<bool> isLoggedIn() async => (await _tokenStorage.getToken()) != null;

  Future<User> getCurrentUser() async {
    final json = await _api.get('/auth/me') as Map<String, dynamic>;
    return User.fromJson(json);
  }

  Future<User> updateProfile({
  String? fullName,
  double? monthlyIncome,
  double? targetSavingsFloor,
  double? currentWalletBalance,
}) async {
  final body = <String, dynamic>{};
  if (fullName != null) body['full_name'] = fullName;
  if (monthlyIncome != null) body['monthly_income'] = monthlyIncome;
  if (targetSavingsFloor != null) body['target_savings_floor'] = targetSavingsFloor;
  if (currentWalletBalance != null) body['current_wallet_balance'] = currentWalletBalance;

  final json = await _api.patch('/auth/me', body);
  return User.fromJson(json);
}

}
