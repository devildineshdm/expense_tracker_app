import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/app_language.dart';
import '../models/transaction_model.dart';

enum DateFilter { today, thisWeek, thisMonth, thisYear, allTime, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _viewType = 'expense';
  DateFilter _filter = DateFilter.thisMonth;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('reports'))),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final filtered = _applyDateFilter(appState.transactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateFilterChips(lang),
                const SizedBox(height: 20),

                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('या कालावधीत data नाही.')),
                  )
                else ...[
                  Text(lang.t('monthly_chart_title'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(height: 220, child: _buildMonthlyBarChart(filtered)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.t('category_chart_title'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                              value: 'expense', label: Text(lang.t('expense'))),
                          ButtonSegment(
                              value: 'income', label: Text(lang.t('income'))),
                        ],
                        selected: {_viewType},
                        onSelectionChanged: (val) =>
                            setState(() => _viewType = val.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                      height: 260,
                      child: _buildCategoryPieChart(filtered, appState)),
                  const SizedBox(height: 16),
                  _buildCategoryLegend(filtered, appState),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilterChips(AppLanguage lang) {
    final options = <DateFilter, String>{
      DateFilter.today: lang.t('today'),
      DateFilter.thisWeek: lang.t('this_week'),
      DateFilter.thisMonth: lang.t('this_month'),
      DateFilter.thisYear: lang.t('this_year'),
      DateFilter.allTime: lang.t('all_time'),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...options.entries.map((e) {
          final selected = _filter == e.key;
          return ChoiceChip(
            label: Text(e.value),
            selected: selected,
            onSelected: (_) => setState(() {
              _filter = e.key;
              _customRange = null;
            }),
          );
        }),
        ChoiceChip(
          label: Text(_customRange == null
              ? lang.t('custom_range')
              : '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}'),
          selected: _filter == DateFilter.custom,
          onSelected: (_) async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
              initialDateRange: _customRange,
            );
            if (picked != null) {
              setState(() {
                _filter = DateFilter.custom;
                _customRange = picked;
              });
            }
          },
        ),
      ],
    );
  }

  List<TransactionModel> _applyDateFilter(List<TransactionModel> all) {
    final now = DateTime.now();
    switch (_filter) {
      case DateFilter.today:
        return all
            .where((t) =>
                t.date.year == now.year &&
                t.date.month == now.month &&
                t.date.day == now.day)
            .toList();
      case DateFilter.thisWeek:
        final startOfWeek =
            now.subtract(Duration(days: now.weekday - 1));
        final startDate =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return all.where((t) => t.date.isAfter(startDate) ||
            _isSameDay(t.date, startDate)).toList();
      case DateFilter.thisMonth:
        return all
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
      case DateFilter.thisYear:
        return all.where((t) => t.date.year == now.year).toList();
      case DateFilter.allTime:
        return all;
      case DateFilter.custom:
        if (_customRange == null) return all;
        final start = _customRange!.start;
        final end = _customRange!.end.add(const Duration(days: 1));
        return all
            .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
            .toList();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildMonthlyBarChart(List<TransactionModel> txns) {
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

  Widget _buildCategoryPieChart(
      List<TransactionModel> txns, AppState appState) {
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
          final catInfo = appState.findCategory(_viewType, e.key);
          return PieChartSectionData(
            value: e.value,
            title: '${percent.toStringAsFixed(0)}%',
            color: catInfo?.color ?? Colors.grey,
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

  Widget _buildCategoryLegend(List<TransactionModel> txns, AppState appState) {
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
        final catInfo = appState.findCategory(_viewType, e.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: catInfo?.color ?? Colors.grey,
                child: catInfo != null
                    ? Icon(catInfo.icon, color: Colors.white, size: 12)
                    : null,
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
