import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book.dart';
import '../models/expense.dart';

class BookRepository {
  BookRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _usersCollection = (firestore ?? FirebaseFirestore.instance).collection('users');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _usersCollection;

  CollectionReference<Map<String, dynamic>> _booksFor(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('books')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (value, _) => value,
        );
  }

  Future<List<Book>> fetchBooks(String userId) async {
    try {
      return await _fetchBooksFromSource(userId);
    } on FirebaseException catch (error) {
      if (_isOfflineError(error)) {
        return _fetchBooksFromSource(userId, source: Source.cache);
      }
      rethrow;
    }
  }

  Stream<List<Book>> watchBooks(String userId) {
    return _booksFor(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Book.fromMap(doc.id, doc.data())).toList());
  }

  Future<Book?> fetchBook(String userId, String bookId) async {
    try {
      return await _fetchBookFromSource(userId, bookId);
    } on FirebaseException catch (error) {
      if (_isOfflineError(error)) {
        return _fetchBookFromSource(userId, bookId, source: Source.cache);
      }
      rethrow;
    }
  }

  Stream<Book?> watchBook(String userId, String bookId) {
    return _booksFor(userId).doc(bookId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return Book.fromMap(snapshot.id, data);
    });
  }

  Future<Book> createBook(String userId, String title) async {
    final collection = _booksFor(userId);
    final docRef = await collection.add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'expenses': <Map<String, dynamic>>[],
      'userId': userId,
    });

    final snapshot = await docRef.get();
    final data = snapshot.data() ?? <String, dynamic>{'title': title, 'expenses': []};
    return Book.fromMap(snapshot.id, data);
  }

  Future<void> addExpense(String userId, String bookId, Expense expense) async {
    final docRef = _booksFor(userId).doc(bookId);
    await docRef.update({
      'expenses': FieldValue.arrayUnion([expense.toMap()]),
    });
  }

  Future<void> deleteBook(String userId, String bookId) async {
    await _booksFor(userId).doc(bookId).delete();
  }

  Future<void> updateExpense(String userId, String bookId, Expense expense) async {
    final existing = await fetchBook(userId, bookId);
    if (existing == null) {
      throw StateError('Book not found');
    }

    final expenses = [...existing.expenses];
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      throw StateError('Expense not found');
    }

    expenses[index] = expense;

    await _booksFor(userId).doc(bookId).update({
      'expenses': expenses.map((item) => item.toMap()).toList(),
    });
  }

  Future<List<Book>> _fetchBooksFromSource(
    String userId, {
    Source source = Source.serverAndCache,
  }) async {
    final snapshot = await _booksFor(userId).orderBy('createdAt', descending: true).get(
          GetOptions(source: source),
        );
    return snapshot.docs.map((doc) => Book.fromMap(doc.id, doc.data())).toList();
  }

  Future<Book?> _fetchBookFromSource(
    String userId,
    String bookId, {
    Source source = Source.serverAndCache,
  }) async {
    final snapshot = await _booksFor(userId).doc(bookId).get(GetOptions(source: source));
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return Book.fromMap(snapshot.id, data);
  }

  bool _isOfflineError(FirebaseException error) {
    return error.code == 'unavailable' || error.code == 'failed-precondition';
  }
}
