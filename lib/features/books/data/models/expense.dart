import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { expense, income }

class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.receiptData,
    this.type = ExpenseType.expense,
    this.categoryId = 'other',
    this.categoryLabel,
    this.categoryColorValue,
    this.categoryIconId,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String? receiptData;
  final ExpenseType type;
  final String categoryId;

  // Denormalized display info, only stored for custom (non-built-in)
  // categories so they render without a separate lookup.
  final String? categoryLabel;
  final int? categoryColorValue;
  final String? categoryIconId;

  bool get isIncome => type == ExpenseType.income;
  bool get isExpense => type == ExpenseType.expense;

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? receiptData,
    ExpenseType? type,
    String? categoryId,
    String? categoryLabel,
    int? categoryColorValue,
    String? categoryIconId,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      receiptData: receiptData ?? this.receiptData,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      categoryIconId: categoryIconId ?? this.categoryIconId,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] as String? ?? 'expense').toLowerCase();
    return Expense(
      id: map['id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: _parseDate(map['date']),
      receiptData: (map['receiptData'] as String?) ?? map['imagePath'] as String?,
      type: rawType == 'income' ? ExpenseType.income : ExpenseType.expense,
      categoryId: (map['categoryId'] as String? ?? map['category'] as String? ?? 'other')
          .toLowerCase(),
      categoryLabel: map['categoryLabel'] as String?,
      categoryColorValue: (map['categoryColorValue'] as num?)?.toInt(),
      categoryIconId: map['categoryIconId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'categoryId': categoryId,
      if (categoryLabel != null && categoryLabel!.isNotEmpty) 'categoryLabel': categoryLabel,
      if (categoryColorValue != null) 'categoryColorValue': categoryColorValue,
      if (categoryIconId != null && categoryIconId!.isNotEmpty) 'categoryIconId': categoryIconId,
      if (receiptData != null && receiptData!.isNotEmpty) 'receiptData': receiptData,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
