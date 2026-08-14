import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/scenario_repository.dart';
import '../domain/scenario_model.dart';

class ScenarioProvider extends ChangeNotifier {
  final ScenarioRepository _repository;

  ScenarioProvider(this._repository);

  bool isLoading = false;
  String? errorMessage;
  ScenarioResult? result;

  Future<void> simulate({
    required double proposedAmount,
    required String category,
    double essentialAllowanceRemaining = 0,
  }) async {
    isLoading = true;
    errorMessage = null;
    result = null;
    notifyListeners();
    try {
      result = await _repository.simulate(
        proposedAmount: proposedAmount,
        category: category,
        essentialAllowanceRemaining: essentialAllowanceRemaining,
      );
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    result = null;
    errorMessage = null;
    notifyListeners();
  }
}