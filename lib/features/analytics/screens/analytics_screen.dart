import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/transactions/data/transaction_model.dart';
import '../../../features/transactions/providers/transaction_provider.dart';
import '../../../core/providers/settings_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedMonth = DateTime.now().month - 1;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<Map<String, dynamic>> get _categoryMeta => [
    {'icon': '🍔', 'label': 'Food', 'color': context.colors.catFood},
    {'icon': '🚗', 'label': 'Transport', 'color': context.colors.catTransport},
    {'icon': '🛍️', 'label': 'Shopping', 'color': context.colors.catShopping},
    {'icon': '💊', 'label': 'Health', 'color': context.colors.catHealth},
    {'icon': '🎮', 'label': 'Fun', 'color': context.colors.catEntertainment},
    {'icon': '🏠', 'label': 'Bills', 'color': context.colors.catBills},
    {'icon': '💰', 'label': 'Salary', 'color': context.colors.primary},
    {'icon': '📦', 'label': 'Other', 'color': context.colors.catOther},
  ];

  // Filter transactions by selected month/year
  List<TransactionModel> _filterByMonth(List<TransactionModel> all) {
    return all.where((t) =>
    t.date.month == _selectedMonth + 1 &&
        t.date.year == _selectedYear).toList();
  }

  // Calculate spent per category
  Map<String, double> _calcCategorySpent(List<TransactionModel> txns) {
    final Map<String, double> map = {};
    for (final t in txns) {
      if (t.isExpense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  // Calculate daily spending
  List<double> _calcDailySpent(List<TransactionModel> txns) {
    final daysInMonth = DateTime(
      _selectedYear,
      _selectedMonth + 2,
      0,
    ).day;
    final List<double> daily = List.filled(daysInMonth, 0);
    for (final t in txns) {
      if (t.isExpense) {
        daily[t.date.day - 1] += t.amount;
      }
    }
    return daily;
  }

  // Get color for category
  Color _categoryColor(String label) {
    final meta = _categoryMeta.firstWhere(
          (m) => m['label'] == label,
      orElse: () => {'color': context.colors.catOther},
    );
    return meta['color'] as Color;
  }

  // Get icon for category
  String _categoryIcon(String label) {
    final meta = _categoryMeta.firstWhere(
          (m) => m['label'] == label,
      orElse: () => {'icon': '📦'},
    );
    return meta['icon'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final allTransactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: context.colors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  // Month selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedMonth > 0) {
                                _selectedMonth--;
                              } else {
                                _selectedMonth = 11;
                                _selectedYear--;
                              }
                            });
                          },
                          child: Icon(
                            Icons.chevron_left,
                            color: context.colors.textSecondary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_months[_selectedMonth]} $_selectedYear',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedMonth < 11) {
                                _selectedMonth++;
                              } else {
                                _selectedMonth = 0;
                                _selectedYear++;
                              }
                            });
                          },
                          child: Icon(
                            Icons.chevron_right,
                            color: context.colors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: allTransactionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: TextStyle(color: context.colors.expense),
                  ),
                ),
                data: (allTransactions) {
                  final txns = _filterByMonth(allTransactions);
                  final categorySpent = _calcCategorySpent(txns);
                  final dailySpent = _calcDailySpent(txns);
                  final maxDaily = dailySpent.isEmpty
                      ? 1.0
                      : dailySpent.reduce((a, b) => a > b ? a : b);
                  final effectiveMax = maxDaily == 0 ? 1.0 : maxDaily;

                  final totalSpent = txns
                      .where((t) => t.isExpense)
                      .fold(0.0, (sum, t) => sum + t.amount);
                  final totalIncome = txns
                      .where((t) => !t.isExpense)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  // Sort categories by spent
                  final sortedCategories = categorySpent.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      children: [
                        // Summary cards
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'Total Spent',
                                '${ref.watch(currencySymbolProvider)} ${totalSpent.toStringAsFixed(0)}',
                                context.colors.expense,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'Total Income',
                                '${ref.watch(currencySymbolProvider)} ${totalIncome.toStringAsFixed(0)}',
                                context.colors.income,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Pie chart
                        Container(
                          padding: const EdgeInsets.all(
                            AppSpacing.cardPadding,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spending by category',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              categorySpent.isEmpty
                                  ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No expenses this month',
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                                  : Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CustomPaint(
                                      painter: _PieChartPainter(
                                        sortedCategories,
                                        totalSpent,
                                            (l) => _categoryColor(l),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      children: sortedCategories
                                          .take(6)
                                          .map((e) {
                                        final pct = totalSpent > 0
                                            ? e.value /
                                            totalSpent *
                                            100
                                            : 0.0;
                                        return Padding(
                                          padding:
                                          const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration:
                                                BoxDecoration(
                                                  color: _categoryColor(
                                                    e.key,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  e.key,
                                                  style:
                                                  const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${pct.toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                  FontWeight.w500,
                                                  color: AppColors
                                                      .textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Daily bar chart
                        Container(
                          padding: const EdgeInsets.all(
                            AppSpacing.cardPadding,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily spending',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 80,
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: List.generate(
                                    dailySpent.length,
                                        (i) {
                                      final h =
                                          dailySpent[i] / effectiveMax;
                                      return Expanded(
                                        child: Padding(
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          child: Container(
                                            height: 70 * h + 2,
                                            decoration: BoxDecoration(
                                              color: context.colors.primary
                                                  .withOpacity(
                                                h > 0 ? 0.7 : 0.1,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '1',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.colors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    '${dailySpent.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.colors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Top categories
                        Container(
                          padding: const EdgeInsets.all(
                            AppSpacing.cardPadding,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top spending categories',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              sortedCategories.isEmpty
                                  ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'No data for this month',
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                                  : Column(
                                children: sortedCategories
                                    .take(3)
                                    .map(
                                      (e) => Padding(
                                    padding:
                                    const EdgeInsets.only(
                                      bottom: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _categoryIcon(e.key),
                                          style: TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors
                                                  .textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${ref.watch(currencySymbolProvider)} ${e.value.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: _categoryColor(
                                              e.key,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final Color Function(String) getColor;

  _PieChartPainter(this.categories, this.total, this.getColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -3.14159 / 2;

    for (final c in categories) {
      final sweepAngle = c.value / total * 2 * 3.14159;
      final paint = Paint()
        ..color = getColor(c.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}