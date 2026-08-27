import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/wallet_model.dart';
import 'wallet_provider.dart';
import 'wallet_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class WalletSimulatorScreen extends StatefulWidget {
  const WalletSimulatorScreen({super.key});

  @override
  State<WalletSimulatorScreen> createState() => _WalletSimulatorScreenState();
}

class _WalletSimulatorScreenState extends State<WalletSimulatorScreen> {
  final _goalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final result = wallet.lastSimulation;

    return Scaffold(
      backgroundColor: WalletPalette.canvasBottom,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.66),
                border: const Border(bottom: BorderSide(color: WalletPalette.hairline)),
              ),
            ),
          ),
        ),
        title: const Text('Unallocated Funds Advisor',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: WalletPalette.ink)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WalletAmbientBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "Got leftover money after budgeting? Tell the AI what you're thinking, or leave it blank for a general recommendation.",
                  style: TextStyle(fontSize: 14, color: WalletPalette.textMuted),
                ),
                const SizedBox(height: 16),
                SheetTextField(
                  controller: _goalController,
                  label: 'What are you considering? (optional)',
                  icon: Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(height: 16),
                SheetPrimaryButton(
                  label: 'Get Recommendation',
                  loading: wallet.isSimulating,
                  colors: const [WalletPalette.accentBlueStart, WalletPalette.accentBlueEnd],
                  onTap: () => context.read<WalletProvider>().simulateUnallocated(
                        goalDescription: _goalController.text.trim().isEmpty
                            ? null
                            : _goalController.text.trim(),
                      ),
                ),
                if (wallet.errorMessage != null && result == null) ...[
                  const SizedBox(height: 12),
                  Text(wallet.errorMessage!, style: const TextStyle(color: WalletPalette.danger)),
                ],
                if (result != null) ...[
                  const SizedBox(height: 24),
                  _ResultCard(result: result),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final UnallocatedSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WalletPalette.accentBlueStart, WalletPalette.accentBlueEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: WalletPalette.accentBlueStart.withOpacity(0.24),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unallocated: ${_currency.format(result.unallocatedBalance)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(result.recommendationSummary,
                        style: const TextStyle(fontSize: 14, color: Colors.white)),
                  ],
                ),
              ),
              GlassSheen(radius: BorderRadius.circular(20)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WalletPalette.amberStart.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WalletPalette.glassBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: WalletPalette.amberStart),
              const SizedBox(width: 10),
              Expanded(
                child: Text(result.riskNote,
                    style: const TextStyle(fontSize: 13, color: WalletPalette.ink)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Suggested Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: WalletPalette.ink)),
        const SizedBox(height: 8),
        ...result.suggestedActions.map(
          (action) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WalletPalette.glassBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline, color: WalletPalette.primaryStart),
              title: Text(action.action,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: WalletPalette.ink)),
              subtitle: Text(action.reasoning, style: const TextStyle(color: WalletPalette.textMuted)),
              trailing: Text(
                _currency.format(action.suggestedAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, color: WalletPalette.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
