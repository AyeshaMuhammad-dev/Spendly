import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/transactions/providers/transaction_provider.dart';
import '../data/budget_repository.dart';

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
  final List<Map<String, dynamic>> _categories = [
    {'icon': '🍔', 'label': 'Food', 'color': AppColors.catFood},
    {'icon': '🚗', 'label': 'Transport', 'color': AppColors.catTransport},
    {'icon': '🛍️', 'label': 'Shopping', 'color': AppColors.catShopping},
    {'icon': '💊', 'label': 'Health', 'color': AppColors.catHealth},
    {'icon': '🎮', 'label': 'Fun', 'color': AppColors.catEntertainment},
    {'icon': '🏠', 'label': 'Bills', 'color': AppColors.catBills},
  ];

  // Default budget limits
  Map<String, double> _limits = {
    'Food': 5000,
    'Transport': 2000,
    'Shopping': 8000,
    'Health': 2000,
    'Fun': 3000,
    'Bills': 3000,
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
      final limit = _limits[label] ?? 1;
      final pct = (spent / limit).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: pct).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
    }).toList();
    _controller.reset();
    _controller.forward();
  }

  Color _barColor(double spent, double total) {
    final pct = spent / total;
    if (pct >= 1.0) return AppColors.expense;
    if (pct >= 0.9) return AppColors.warning;
    return AppColors.income;
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit $category Budget',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter budget amount',
            prefixText: 'Rs ',
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

    // Update limits from Firestore if available
    budgetLimitsAsync.whenData((limits) {
      if (limits.isNotEmpty) {
        _limits = {..._limits, ...limits};
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
                data: (transactions) {
                  final spentMap = _calculateSpent(transactions);
                  _updateAnimations(spentMap);

                  final totalBudget =
                  _limits.values.fold(0.0, (a, b) => a + b);
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Overview',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
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
                                      const Text(
                                        'Total Budget',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Rs ${totalBudget.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Total Spent',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Rs ${totalSpent.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.expense,
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
                                  backgroundColor: AppColors.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _barColor(totalSpent, totalBudget),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rs ${(totalBudget - totalSpent).toStringAsFixed(0)} remaining',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
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
                          final total = _limits[label] ?? 1;
                          final pct = spent / total;
                          final isOver = pct >= 1.0;

                          return AnimatedBuilder(
                            animation: _animations[i],
                            builder: (context, _) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(
                                  AppSpacing.cardPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadius,
                                  ),
                                  border: isOver
                                      ? Border.all(
                                    color: AppColors.expense
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
                                          style: const TextStyle(
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
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                'Rs ${spent.toStringAsFixed(0)} / Rs ${total.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
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
                                              color: AppColors.surfaceVariant,
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
                                        AppColors.surfaceVariant,
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