import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // Delete all transactions for the current user
  Future<void> deleteAllTransactions() async {
    final snapshots = await _collection.get();
    if (snapshots.docs.isEmpty) return;

    // Firestore batch has a limit of 500 operations
    for (var i = 0; i < snapshots.docs.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = snapshots.docs.skip(i).take(500);
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // Delete all user data (Firestore and Storage)
  Future<void> deleteUserAllData() async {
    final userId = _userId;
    if (userId.isEmpty) return;

    // 1. Delete transactions subcollection
    await deleteAllTransactions();

    // 2. Delete settings/budgets
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('budgets')
        .delete();

    // 3. Delete user document
    await _firestore.collection('users').doc(userId).delete();

    // 4. Delete profile photo from Storage
    try {
      await FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg')
          .delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
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

  // Get all transactions as a future
  Future<List<TransactionModel>> getAllTransactionsFuture() async {
    final snapshot = await _collection.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) {
      return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
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