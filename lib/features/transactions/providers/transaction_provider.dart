import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';

// Repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// Stream of ALL transactions (real time)
final transactionsStreamProvider =
StreamProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions();
});

// Stream of MONTHLY transactions (real time)
final monthlyTransactionsProvider =
StreamProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getMonthlyTransactions();
});

// Total income this month
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  return transactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Total expense this month
final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  return transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Balance
final balanceProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
});

// Add transaction notifier
class AddTransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repo;

  AddTransactionNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required String icon,
    required DateTime date,
    required bool isExpense,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        category: category,
        icon: icon,
        date: date,
        userId: userId,
        isExpense: isExpense,
        note: note,
      );
      await _repo.addTransaction(transaction);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
  }
}

final addTransactionProvider =
StateNotifierProvider<AddTransactionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return AddTransactionNotifier(repo);
});