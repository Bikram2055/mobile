import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/book.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/book_repository.dart';

class BookController extends ChangeNotifier {
  BookController({required BookRepository repository}) : _repository = repository;

  final BookRepository _repository;
  final List<Book> _books = <Book>[];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _userId;

  List<Book> get books => List.unmodifiable(_books);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasUser => _userId != null;

  Book? bookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } on StateError {
      return null;
    }
  }

  void attachUser(String? userId) {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    _books.clear();
    _errorMessage = null;
    notifyListeners();
    if (_userId != null) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    if (_userId == null) {
      return;
    }
    _setLoading(true);
    try {
      final items = await _repository.fetchBooks(_userId!);
      _books
        ..clear()
        ..addAll(items);
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = 'Something went wrong while loading your books.';
      debugPrint('Failed to fetch books: $error\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<Book?> addBook(String title) async {
    if (_userId == null) {
      _errorMessage = 'Please sign in to add a book.';
      notifyListeners();
      return null;
    }
    if (title.trim().isEmpty) {
      _errorMessage = 'Book title cannot be empty';
      notifyListeners();
      return null;
    }

    _setSaving(true);
    try {
      final created = await _repository.createBook(_userId!, title.trim());
      _books.insert(0, created);
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to add the book right now.';
      debugPrint('Failed to add book: $error\n$stackTrace');
      notifyListeners();
      return null;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> addExpense({
    required String bookId,
    required Expense expense,
  }) async {
    if (_userId == null) {
      _errorMessage = 'Please sign in to add an expense.';
      notifyListeners();
      return;
    }
    _setSaving(true);
    // Optimistically update UI immediately.
    _applyLocalAdd(bookId, expense);
    _errorMessage = null;
    notifyListeners();
    _setSaving(false);

    // Fire-and-forget remote update; Firestore will queue it offline.
    unawaited(
      _repository.addExpense(_userId!, bookId, expense).catchError((error, stackTrace) {
        if (!_isOfflineOrNetwork(error)) {
          _errorMessage = 'We couldn\'t save that expense. Please try again.';
          debugPrint('Failed to add expense: $error\n$stackTrace');
          notifyListeners();
        }
      }),
    );
  }

  Future<bool> deleteBook(String bookId) async {
    if (_userId == null) {
      _errorMessage = 'Please sign in to delete this book.';
      notifyListeners();
      return false;
    }
    _setSaving(true);
    try {
      await _repository.deleteBook(_userId!, bookId);
      _books.removeWhere((book) => book.id == bookId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to delete the book right now.';
      debugPrint('Failed to delete book: $error\n$stackTrace');
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> updateExpense({
    required String bookId,
    required Expense expense,
  }) async {
    if (_userId == null) {
      _errorMessage = 'Please sign in to update this expense.';
      notifyListeners();
      return false;
    }
    _setSaving(true);
    final updated = _applyLocalUpdate(bookId, expense);
    if (!updated) {
      _setSaving(false);
      return false;
    }

    _errorMessage = null;
    notifyListeners();
    _setSaving(false);

    unawaited(
      _repository.updateExpense(_userId!, bookId, expense).catchError((error, stackTrace) {
        if (_isOfflineOrNetwork(error)) {
          return;
        }
        _errorMessage = 'We couldn\'t update that expense. Please try again.';
        debugPrint('Failed to update expense: $error\n$stackTrace');
        notifyListeners();
      }),
    );

    return true;
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) {
      return;
    }
    _isSaving = value;
    notifyListeners();
  }

  void _applyLocalAdd(String bookId, Expense expense) {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index == -1) {
      return;
    }
    final updatedExpenses = <Expense>[..._books[index].expenses, expense];
    _books[index] = _books[index].copyWith(expenses: updatedExpenses);
  }

  bool _applyLocalUpdate(String bookId, Expense expense) {
    final bookIndex = _books.indexWhere((book) => book.id == bookId);
    if (bookIndex == -1) {
      _errorMessage = 'Book not found locally.';
      return false;
    }

    final expenses = [..._books[bookIndex].expenses];
    final expenseIndex = expenses.indexWhere((item) => item.id == expense.id);
    if (expenseIndex == -1) {
      _errorMessage = 'Expense not found locally.';
      return false;
    }

    expenses[expenseIndex] = expense;
    _books[bookIndex] = _books[bookIndex].copyWith(expenses: expenses);
    return true;
  }

  bool _isOfflineOrNetwork(Object error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'failed-precondition' ||
          error.code == 'network-request-failed';
    }
    return false;
  }
}
