import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/transactions/providers/transaction_provider.dart';
import '../data/budget_repository.dart';
import '../../../core/providers/settings_provider.dart';
import '../../transactions/screens/add_expense_screen.dart';

// Budget repository provider
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

// Budget limits stream provider
final budgetLimitsProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(budgetRepositoryProvider).getBudgetLimits();
});

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  // Default budget categories with limits
  List<Map<String, dynamic>> get _categories => [
    {'icon': '🍔', 'label': 'Food', 'color': context.colors.catFood},
    {'icon': '🚗', 'label': 'Transport', 'color': context.colors.catTransport},
    {'icon': '🛍️', 'label': 'Shopping', 'color': context.colors.catShopping},
    {'icon': '💊', 'label': 'Health', 'color': context.colors.catHealth},
    {'icon': '🎮', 'label': 'Fun', 'color': context.colors.catEntertainment},
    {'icon': '🏠', 'label': 'Bills', 'color': context.colors.catBills},
  ];

  // Default budget limits (Start with 0, user sets them)
  Map<String, double> _limits = {
    'Food': 0,
    'Transport': 0,
    'Shopping': 0,
    'Health': 0,
    'Fun': 0,
    'Bills': 0,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animations = List.generate(
      _categories.length,
          (_) => Tween<double>(begin: 0, end: 0).animate(_controller),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateAnimations(Map<String, double> spentMap) {
    _animations = _categories.map((c) {
      final label = c['label'] as String;
      final spent = spentMap[label] ?? 0;
      final limit = _limits[label] ?? 0;
      final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
      return Tween<double>(begin: 0, end: pct).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
    }).toList();
    _controller.reset();
    _controller.forward();
  }

  Color _barColor(double spent, double total) {
    final pct = spent / total;
    if (pct >= 1.0) return context.colors.expense;
    if (pct >= 0.9) return context.colors.warning;
    return context.colors.income;
  }

  // Calculate spent per category from real transactions
  Map<String, double> _calculateSpent(dynamic transactions) {
    final Map<String, double> spent = {};
    for (final t in transactions) {
      if (t.isExpense) {
        spent[t.category] = (spent[t.category] ?? 0) + t.amount;
      }
    }
    return spent;
  }

  void _showEditDialog(String category) {
    final controller = TextEditingController(
      text: _limits[category]?.toStringAsFixed(0) ?? '0',
    );
    final currencySymbol = ref.read(currencySymbolProvider);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Edit $category Budget',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter budget amount',
            prefixText: '$currencySymbol ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _limits[category] = val);
                // Save to Firestore
                await ref
                    .read(budgetRepositoryProvider)
                    .saveBudgetLimits(_limits);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);
    final budgetLimitsAsync = ref.watch(budgetLimitsProvider);
    final totalIncome = ref.watch(totalIncomeProvider);

    // Listen to transaction changes to update animations safely
    ref.listen(monthlyTransactionsProvider, (previous, next) {
      next.whenData((transactions) {
        final spentMap = _calculateSpent(transactions);
        _updateAnimations(spentMap);
      });
    });

    // Update limits from Firestore if available
    budgetLimitsAsync.whenData((limits) {
      if (limits.isNotEmpty) {
        _limits = {..._limits, ...limits};
      }
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                  Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
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
                data: (transactions) {
                  final spentMap = _calculateSpent(transactions);
                  
                  final totalBudget = totalIncome;
                  final totalSpent =
                  spentMap.values.fold(0.0, (a, b) => a + b);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      children: [
                        // Overview card
                        Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Monthly Overview',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddExpenseScreen(
                                          initialIsExpense: false,
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colors.income.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: context.colors.income.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 14,
                                            color: context.colors.income,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Add Income',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.income,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Budget',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${ref.watch(currencySymbolProvider)} ${totalBudget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: context.colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total Spent',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${ref.watch(currencySymbolProvider)} ${totalSpent.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: context.colors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalBudget > 0
                                      ? (totalSpent / totalBudget)
                                      .clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 8,
                                  backgroundColor: context.colors.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _barColor(totalSpent, totalBudget),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${ref.watch(currencySymbolProvider)} ${(totalBudget - totalSpent).toStringAsFixed(0)} remaining',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Category cards
                        ...List.generate(_categories.length, (i) {
                          final c = _categories[i];
                          final label = c['label'] as String;
                          final spent = spentMap[label] ?? 0;
                          final total = _limits[label] ?? 0;
                          final pct = total > 0 ? (spent / total) : 0.0;
                          final isOver = total > 0 && pct >= 1.0;

                          return AnimatedBuilder(
                            animation: _animations[i],
                            builder: (context, _) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(
                                  AppSpacing.cardPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadius,
                                  ),
                                  border: isOver
                                      ? Border.all(
                                    color: context.colors.expense
                                        .withOpacity(0.4),
                                    width: 1,
                                  )
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c['icon'],
                                          style: TextStyle(
                                            fontSize: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: context.colors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                '${ref.watch(currencySymbolProvider)} ${spent.toStringAsFixed(0)} / ${ref.watch(currencySymbolProvider)} ${total.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.colors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              _showEditDialog(label),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.colors.surfaceVariant,
                                              borderRadius:
                                              BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isOver
                                                  ? 'Over!'
                                                  : '${(pct * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _barColor(spent, total),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _animations[i].value,
                                        minHeight: 6,
                                        backgroundColor:
                                        context.colors.surfaceVariant,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          _barColor(spent, total),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }),

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
}