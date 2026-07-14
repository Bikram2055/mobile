import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    this.createdAt,
    this.expenses = const [],
  });

  final String id;
  final String title;
  final DateTime? createdAt;
  final List<Expense> expenses;

  double get totalSpent =>
      expenses.where((expense) => expense.isExpense).fold(0, (total, expense) => total + expense.amount);
  double get totalIncome =>
      expenses.where((expense) => expense.isIncome).fold(0, (total, expense) => total + expense.amount);
  int get expenseCount => expenses.length;

  Book copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<Expense>? expenses,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      expenses: expenses ?? this.expenses,
    );
  }

  factory Book.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      return Book(id: snapshot.id, title: 'Untitled Book');
    }
    return Book.fromMap(snapshot.id, data);
  }

  factory Book.fromMap(String id, Map<String, dynamic> map) {
    final rawExpenses = map['expenses'] as List<dynamic>? ?? [];
    return Book(
      id: id,
      title: map['title'] as String? ?? 'Untitled Book',
      createdAt: _parseDate(map['createdAt']),
      expenses: rawExpenses
          .map((raw) => Expense.fromMap(Map<String, dynamic>.from(raw as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'expenses': expenses.map((expense) => expense.toMap()).toList(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
