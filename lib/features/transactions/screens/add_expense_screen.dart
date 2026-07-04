import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/transaction_provider.dart';
import '../../../core/providers/settings_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final bool initialIsExpense;
  const AddExpenseScreen({super.key, this.initialIsExpense = true});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late bool _isExpense;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
  }
  int _selectedCategory = 0;
  bool _isLoading = false;
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'icon': '🍔', 'label': 'Food'},
    {'icon': '🚗', 'label': 'Transport'},
    {'icon': '🛍️', 'label': 'Shopping'},
    {'icon': '💊', 'label': 'Health'},
    {'icon': '🎮', 'label': 'Fun'},
    {'icon': '🏠', 'label': 'Bills'},
    {'icon': '💰', 'label': 'Salary'},
    {'icon': '📦', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primary,
              surface: context.colors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (picked == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (picked == yesterday) return 'Yesterday';
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an amount'),
          backgroundColor: context.colors.expense,
        ),
      );
      return;
    }

    // For expense, title is required
    if (_isExpense && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: context.colors.expense,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: context.colors.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(addTransactionProvider.notifier).addTransaction(
        // Income uses "Income" as title, expense uses typed title
        title: _isExpense
            ? _titleController.text.trim()
            : 'Income',
        amount: amount,
        // Income always uses Salary category
        category: _isExpense
            ? _categories[_selectedCategory]['label']
            : 'Salary',
        icon: _isExpense
            ? _categories[_selectedCategory]['icon']
            : '💰',
        date: _selectedDate,
        isExpense: _isExpense,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction saved successfully'),
            backgroundColor: context.colors.income,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.colors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: 12,
              ),
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
                    _isExpense ? 'Add Expense' : 'Add Income',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadiusSm,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _toggleBtn(
                            'Expense',
                            _isExpense,
                                () => setState(() => _isExpense = true),
                            activeColor: context.colors.expense,
                          ),
                          _toggleBtn(
                            'Income',
                            !_isExpense,
                                () => setState(() => _isExpense = false),
                            activeColor: context.colors.income,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount — always visible
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${ref.watch(currencySymbolProvider)} ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _isExpense
                                  ? context.colors.expense
                                  : context.colors.income,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _isExpense
                                    ? context.colors.expense
                                    : context.colors.income,
                                letterSpacing: -0.5,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textTertiary,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // EXPENSE ONLY fields
                    if (_isExpense) ...[
                      const SizedBox(height: 24),

                      // Category
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final isSelected = _selectedCategory == i;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.colors.primaryContainer
                                    : context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                  color: context.colors.primary,
                                  width: 1.5,
                                )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _categories[i]['icon'],
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _categories[i]['label'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? context.colors.primary
                                          : context.colors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style:
                        TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. Lunch at cafe',
                          filled: true,
                          fillColor: context.colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: context.colors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formattedDate,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // INCOME ONLY — just a note
                    if (!_isExpense) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('💰', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              'Income will be added to your balance',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isExpense
                              ? context.colors.expense
                              : context.colors.income,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          _isExpense
                              ? 'Save Expense'
                              : 'Save Income',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
      String label,
      bool active,
      VoidCallback onTap, {
        required Color activeColor,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? Colors.black : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
