class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String icon;
  final DateTime date;
  final String userId;
  final bool isExpense;
  final String? note;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.icon,
    required this.date,
    required this.userId,
    required this.isExpense,
    this.note,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'icon': icon,
      'date': date.toIso8601String(),
      'userId': userId,
      'isExpense': isExpense,
      'note': note ?? '',
    };
  }

  // Create from Firestore map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      icon: map['icon'] ?? '📦',
      date: DateTime.parse(map['date']),
      userId: map['userId'] ?? '',
      isExpense: map['isExpense'] ?? true,
      note: map['note'] ?? '',
    );
  }
}