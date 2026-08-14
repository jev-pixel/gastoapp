import '../../../core/api_client.dart';
import '../domain/scenario_model.dart';

class ScenarioRepository {
  final ApiClient _api;

  ScenarioRepository(this._api);

  Future<ScenarioResult> simulate({
    required double proposedAmount,
    required String category,
    double essentialAllowanceRemaining = 0,
    int? remainingDaysInCycle,
  }) async {
    final json = await _api.post('/scenario/', {
      'proposed_amount': proposedAmount,
      'category': category,
      'essential_allowance_remaining': essentialAllowanceRemaining,
      if (remainingDaysInCycle != null) 'remaining_days_in_cycle': remainingDaysInCycle,
    });
    return ScenarioResult.fromJson(json);
  }
}