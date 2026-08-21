// lib/features/analytics/presentation/spending_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../expenses/presentation/expenses_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../domain/spending_analytics.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dayFormat = DateFormat('MMM d');

// Mirrors the palette used across wallet_screen.dart / dashboard_screen.dart
// so this reads as part of the same app.
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const surface = Color(0xFFF6F8F5);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);
  static const amberStart = Color(0xFFC77D1E);
  static const amberEnd = Color(0xFFE0A23D);
}

class SpendingAnalyticsScreen extends StatefulWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  State<SpendingAnalyticsScreen> createState() => _SpendingAnalyticsScreenState();
}

class _SpendingAnalyticsScreenState extends State<SpendingAnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.last7;
  DateTimeRange? _customRange;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = AnalyticsPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpensesProvider>().expenses;
    final wallet = context.watch<WalletProvider>();
    final allowances = wallet.summary?.allowances ?? const [];

    final result = SpendingAnalyticsEngine.analyze(
      expenses: expenses,
      allowances: allowances,
      walletTransactions: wallet.transactions,
      period: _period,
      customStart: _customRange?.start,
      customEnd: _customRange?.end,
    );

    // Forecast horizon mirrors the analysis window itself — "if the last
    // {N} days keep happening, the next {N} days will look like this."
    final forecastDays = result.daysInWindow;
    final projected = result.projectedSpend(forecastDays);

    return Scaffold(
      backgroundColor: _Palette.surface,
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _PeriodSelector(
              period: _period,
              customLabel: _customRange == null
                  ? null
                  : '${_dayFormat.format(_customRange!.start)} - ${_dayFormat.format(_customRange!.end)}',
              onSelect: (p) {
                if (p == AnalyticsPeriod.custom) {
                  _pickCustomRange();
                } else {
                  setState(() {
                    _period = p;
                    _customRange = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _SummaryCard(result: result),
            const SizedBox(height: 16),
            _DailyBarChart(dailyBreakdown: result.dailyBreakdown),
            const SizedBox(height: 16),
            _ForecastCard(
              forecastDays: forecastDays,
              projectedAmount: projected,
              averageDailySpend: result.averageDailySpend,
            ),
            if (result.atRiskAllowances.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RiskBanner(atRisk: result.atRiskAllowances),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod period;
  final String? customLabel;
  final ValueChanged<AnalyticsPeriod> onSelect;

  const _PeriodSelector({required this.period, required this.customLabel, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget chip(AnalyticsPeriod p, String label) {
      final selected = period == p;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelect(p),
        selectedColor: _Palette.primaryStart,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF14231C),
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? _Palette.primaryStart : _Palette.cardBorder),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(AnalyticsPeriod.last7, '7 Days'),
        chip(AnalyticsPeriod.last14, '14 Days'),
        chip(AnalyticsPeriod.last30, '30 Days'),
        chip(AnalyticsPeriod.custom, customLabel ?? 'Custom'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SpendingAnalyticsResult result;
  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.primaryStart, _Palette.primaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.primaryStart.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SPENT (${result.daysInWindow} DAYS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currency.format(result.totalSpent),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withOpacity(0.16)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average per day',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
              ),
              Text(
                '${_currency.format(result.averageDailySpend)}/day',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final List<DailySpend> dailyBreakdown;
  const _DailyBarChart({required this.dailyBreakdown});

  @override
  Widget build(BuildContext context) {
    if (dailyBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxVal = dailyBreakdown.map((d) => d.total).fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Spend', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dailyBreakdown.map((d) {
                  final heightFraction = maxVal == 0 ? 0.0 : (d.total / maxVal);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.total > 0)
                          Text(
                            _currency.format(d.total).replaceAll('.00', ''),
                            style: const TextStyle(fontSize: 9, color: _Palette.textMuted),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 22,
                          height: 90 * heightFraction.clamp(0.0, 1.0) + 4,
                          decoration: BoxDecoration(
                            color: d.total > 0 ? _Palette.primaryStart : _Palette.cardBorder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('d').format(d.day),
                          style: const TextStyle(fontSize: 11, color: _Palette.textMuted),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final int forecastDays;
  final double projectedAmount;
  final double averageDailySpend;

  const _ForecastCard({
    required this.forecastDays,
    required this.projectedAmount,
    required this.averageDailySpend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F5DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_up_rounded, color: _Palette.primaryStart, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('If this pace continues', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13, color: _Palette.textMuted, height: 1.4),
                    children: [
                      const TextSpan(text: 'At '),
                      TextSpan(
                        text: '${_currency.format(averageDailySpend)}/day',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF14231C)),
                      ),
                      TextSpan(text: ', you\'d spend roughly '),
                      TextSpan(
                        text: _currency.format(projectedAmount),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF14231C)),
                      ),
                      TextSpan(text: ' over the next $forecastDays days.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final List<AllowanceRisk> atRisk;
  const _RiskBanner({required this.atRisk});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.amberStart, _Palette.amberEnd],
        ),
        boxShadow: [
          BoxShadow(color: _Palette.amberStart.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Heads up — spending faster than these allowances can sustain',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...atRisk.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r.allowanceName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      r.daysUntilDepleted == null
                          ? 'Depleted'
                          : '~${r.daysUntilDepleted!.toStringAsFixed(1)} days left',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}