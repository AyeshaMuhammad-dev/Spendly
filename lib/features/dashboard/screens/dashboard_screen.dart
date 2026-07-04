import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/transactions/data/transaction_model.dart';
import '../../../features/transactions/providers/transaction_provider.dart';
import '../../dashboard/screens/main_screen.dart';
import '../../transactions/screens/add_expense_screen.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../../budget/screens/budget_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../../core/providers/settings_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  List<Map<String, dynamic>> _buildWeeklyData(
      List<TransactionModel> transactions,
      ) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = dayLabels[day.weekday - 1];
      final dayTotal = transactions
          .where((t) =>
      t.isExpense &&
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      data.add({'label': label, 'amount': dayTotal, 'date': day});
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final balance = ref.watch(balanceProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: TextStyle(color: context.colors.expense),
            ),
          ),
          data: (transactions) {
            final weeklyData = _buildWeeklyData(transactions);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildBalanceCard(balance, totalIncome, totalExpense, currencySymbol),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(weeklyData),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(transactions),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Header — uses StreamBuilder so name loads correctly
  Widget _buildHeader() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user =
            snapshot.data ?? FirebaseAuth.instance.currentUser;
        final name = user?.displayName ??
            user?.email?.split('@')[0] ??
            'User';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$name 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(
      double balance,
      double totalIncome,
      double totalExpense,
      String currencySymbol,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003D30), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balance < -0.5
                ? '- $currencySymbol ${balance.abs().toStringAsFixed(0)}'
                : '$currencySymbol ${balance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: balance < -0.5
                  ? context.colors.expense
                  : context.colors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: context.colors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currencySymbol ${totalIncome.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.income,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currencySymbol ${totalExpense.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': '➕', 'label': 'Add'},
      {'icon': '📊', 'label': 'Budget'},
      {'icon': '📈', 'label': 'Analytics'},
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (action['label'] == 'Add') {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AddExpenseScreen()));
              } else if (action['label'] == 'Budget') {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const BudgetScreen()));
              } else if (action['label'] == 'Analytics') {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen()));
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(action['icon']!,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    action['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Fixed chart — SizedBox keeps fixed height so labels stay in one row
  Widget _buildWeeklyChart(List<Map<String, dynamic>> weeklyData) {
    final amounts =
    weeklyData.map((d) => d['amount'] as double).toList();
    final maxVal = amounts.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 7 days',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius:
            BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final amount = weeklyData[i]['amount'] as double;
                final label = weeklyData[i]['label'] as String;
                final heightFactor = amount / effectiveMax;
                final isHighest = amount == maxVal && maxVal > 0;
                final date = weeklyData[i]['date'] as DateTime;
                final now = DateTime.now();
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 70 * heightFactor + 2,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isHighest
                              ? context.colors.primary
                              : context.colors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isToday
                              ? context.colors.primary
                              : context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // Only expenses shown
  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    final recent =
    transactions.where((t) => t.isExpense).take(5).toList();
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TransactionsScreen()),
              ),
              child: Text(
                'See all',
                style:
                TextStyle(color: context.colors.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recent.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No expenses yet\nTap + to add one',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
        )
            : Column(
          children: recent
              .map((t) => _buildTransactionRow(t, currencySymbol))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(TransactionModel t, String currencySymbol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.expenseContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(t.icon,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  _formatDate(t.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$currencySymbol ${t.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.expense,
            ),
          ),
        ],
      ),
    );
  }

}
