import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';

class BudgetScreen extends StatelessWidget {
  static const route = '/budget';
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'BudgetScreen',
      onRetry: () {
        // Retry functionality
      },
      child: ChangeNotifierProvider(
        create: (_) => BudgetViewModel(BudgetService(), FirebaseAuth.instance)..load(),
        child: const _BudgetBody(),
      ),
    );
  }
}

class _BudgetBody extends StatelessWidget {
  const _BudgetBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: AccessibleText(s.budget)),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.summary == null
              ? Center(child: AccessibleText(s.error))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText('Year ${vm.summary!.year}',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      SizedBox(height: 220, child: _BudgetPie(summary: vm.summary!)),
                      const SizedBox(height: 12),
                      _BudgetRow(
                          label: 'Core', total: vm.summary!.core, spent: vm.summary!.spentCore),
                      _BudgetRow(
                          label: 'Capacity',
                          total: vm.summary!.capacity,
                          spent: vm.summary!.spentCapacity),
                      _BudgetRow(
                          label: 'Capital',
                          total: vm.summary!.capital,
                          spent: vm.summary!.spentCapital),
                      const SizedBox(height: 8),
                      AccessibleText(
                        'Tip: set alerts to avoid overspending. Alerts via Functions trigger push notifications when you near limits.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _BudgetPie extends StatelessWidget {
  final BudgetSummary summary;
  const _BudgetPie({required this.summary});

  @override
  Widget build(BuildContext context) {
    final remaining = summary.remainingCore + summary.remainingCapacity + summary.remainingCapital;
    final spent = summary.spentCore + summary.spentCapacity + summary.spentCapital;
    final total = remaining + spent;

    if (total == 0) {
      return const Center(child: AccessibleText('No budget data available'));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: remaining,
            title: 'Remaining\n${remaining.toStringAsFixed(0)}',
            color: Colors.green,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: spent,
            title: 'Spent\n${spent.toStringAsFixed(0)}',
            color: Colors.red,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}

// Removed _Slice class as it's no longer needed with fl_chart

class _BudgetRow extends StatelessWidget {
  final String label;
  final double total;
  final double spent;
  const _BudgetRow({required this.label, required this.total, required this.spent});

  @override
  Widget build(BuildContext context) {
    final remaining = (total - spent).clamp(0, total);
    final pct = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AccessibleText(label, style: Theme.of(context).textTheme.titleSmall),
            AccessibleText(
                '${remaining.toStringAsFixed(0)} remaining / ${total.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: pct, minHeight: 10),
        const SizedBox(height: 8),
      ],
    );
  }
}
