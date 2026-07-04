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

// Total income this month (for display on dashboard card)
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  return transactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Total expense this month (for display on dashboard card)
final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  return transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// All-time total income (used for balance calculation)
final allTimeIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  return transactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// All-time total expense (used for balance calculation)
final allTimeExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  return transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Balance = all-time income minus all-time expenses
final balanceProvider = Provider<double>((ref) {
  final income = ref.watch(allTimeIncomeProvider);
  final expense = ref.watch(allTimeExpenseProvider);
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

  Future<void> deleteAllTransactions() async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAllTransactions();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      // 1. Delete all data from Firestore and Storage
      await _repo.deleteUserAllData();
      
      // 2. Delete the user account from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }
}

final addTransactionProvider =
StateNotifierProvider<AddTransactionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return AddTransactionNotifier(repo);
});