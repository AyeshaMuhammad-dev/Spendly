import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction_model.dart';

class TransactionRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get current user ID
  String get _userId => _auth.currentUser?.uid ?? '';

  // Collection reference for current user
  CollectionReference get _collection => _firestore
      .collection('users')
      .doc(_userId)
      .collection('transactions');

  // Save a transaction to Firestore
  Future<void> addTransaction(TransactionModel transaction) async {
    await _collection.doc(transaction.id).set(transaction.toMap());
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _collection.doc(id).delete();
  }

  // Get all transactions as a stream (real time)
  Stream<List<TransactionModel>> getTransactions() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get transactions for current month only
  Stream<List<TransactionModel>> getMonthlyTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((t) =>
      t.date.isAfter(startOfMonth) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1))))
          .toList();
    });
  }
}