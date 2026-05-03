import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  DocumentReference get _budgetDoc =>
      _firestore.collection('users').doc(_userId).collection('settings').doc('budgets');

  // Save budget limits to Firestore
  Future<void> saveBudgetLimits(Map<String, double> limits) async {
    await _budgetDoc.set(limits);
  }

  // Get budget limits from Firestore
  Stream<Map<String, double>> getBudgetLimits() {
    return _budgetDoc.snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
    });
  }
}