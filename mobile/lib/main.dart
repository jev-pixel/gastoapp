import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/edit_profile_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/expenses/data/expense_repository.dart';
import 'features/expenses/presentation/expenses_provider.dart';
import 'features/expenses/presentation/expenses_screen.dart';
import 'features/scenario_ai/data/scenario_repository.dart';
import 'features/scenario_ai/presentation/scenario_input_screen.dart';
import 'features/scenario_ai/presentation/scenario_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // must be first line

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authRepository = AuthRepository(apiClient, tokenStorage);
  final expenseRepository = ExpenseRepository(apiClient);
  final scenarioRepository = ScenarioRepository(apiClient);

  final authProvider = AuthProvider(authRepository)..checkLoginState();

  apiClient.onUnauthorized = () {
    authProvider.forceLogout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => ExpensesProvider(expenseRepository)),
        ChangeNotifierProvider(create: (_) => ScenarioProvider(scenarioRepository)),
      ],
      child: const GastoApp(),
    ),
  );
}

class GastoApp extends StatelessWidget {
  const GastoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'GastoApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      initialRoute: '/login',
    routes: {
      '/login': (_) => const LoginScreen(),
      '/dashboard': (_) => const DashboardScreen(),
      '/expenses': (_) => const ExpensesScreen(),
      '/scenario': (_) => const ScenarioInputScreen(),
      '/edit-profile': (_) => const EditProfileScreen(), // new
    },
    );
  }
}