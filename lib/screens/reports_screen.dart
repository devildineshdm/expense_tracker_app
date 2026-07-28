import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _viewType = 'expense'; // pie chart kashasathi dakhvaycha

  final List<Color> _palette = [
    Colors.blue, Colors.orange, Colors.purple, Colors.teal,
    Colors.pink, Colors.brown, Colors.indigo, Colors.amber,
    Colors.cyan, Colors.deepOrange, Colors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final txns = appState.transactions;
          if (txns.isEmpty) {
            return const Center(child: Text('Data नाही, आधी entries टाका.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('महिन्यानुसार Income vs Expense',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(height: 220, child: _buildMonthlyBarChart(txns)),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Category नुसार विभागणी',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('Expense')),
                        ButtonSegment(value: 'income', label: Text('Income')),
                      ],
                      selected: {_viewType},
                      onSelectionChanged: (val) =>
                          setState(() => _viewType = val.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(height: 260, child: _buildCategoryPieChart(txns)),
                const SizedBox(height: 16),
                _buildCategoryLegend(txns),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<TransactionModel> txns) {
    // Magil 6 mahine cha data group karto
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      return d;
    });

    final incomeByMonth = <double>[];
    final expenseByMonth = <double>[];

    for (final m in months) {
      final income = txns
          .where((t) =>
              t.type == 'income' && t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = txns
          .where((t) =>
              t.type == 'expense' && t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (sum, t) => sum + t.amount);
      incomeByMonth.add(income);
      expenseByMonth.add(expense);
    }

    final maxVal = [...incomeByMonth, ...expenseByMonth]
        .fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxVal == 0 ? 100 : maxVal * 1.2,
        barGroups: List.generate(months.length, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
                toY: incomeByMonth[i], color: Colors.green, width: 8),
            BarChartRodData(
                toY: expenseByMonth[i], color: Colors.red, width: 8),
          ]);
        }),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= months.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('MMM').format(months[idx]),
                      style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCategoryPieChart(List<TransactionModel> txns) {
    final filtered = txns.where((t) => t.type == _viewType).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('या प्रकारचा data नाही'));
    }

    final Map<String, double> totals = {};
    for (final t in filtered) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = totals.values.fold(0.0, (a, b) => a + b);

    return PieChart(
      PieChartData(
        sections: List.generate(entries.length, (i) {
          final e = entries[i];
          final percent = (e.value / total * 100);
          return PieChartSectionData(
            value: e.value,
            title: '${percent.toStringAsFixed(0)}%',
            color: _palette[i % _palette.length],
            radius: 90,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildCategoryLegend(List<TransactionModel> txns) {
    final filtered = txns.where((t) => t.type == _viewType).toList();
    final Map<String, double> totals = {};
    for (final t in filtered) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
      children: List.generate(entries.length, (i) {
        final e = entries[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _palette[i % _palette.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.key)),
              Text(fmt.format(e.value),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }),
    );
  }
}
