import '../../books/data/models/book.dart';
import '../../books/data/models/expense.dart';
import '../../books/data/models/expense_category.dart';

/// Aggregated total for a single category, ready to feed the charts.
class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.total,
    required this.count,
    required this.share,
  });

  final ExpenseCategory category;

  /// Sum of the amounts in this category.
  final double total;

  /// Number of entries that make up [total].
  final int count;

  /// Fraction of the grand total this category represents (0..1).
  final double share;
}

/// Result of aggregating a set of books for a single [ExpenseType].
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.slices,
    required this.total,
    required this.entryCount,
  });

  final List<CategorySlice> slices;
  final double total;
  final int entryCount;

  bool get isEmpty => slices.isEmpty;
  int get categoryCount => slices.length;

  CategorySlice? get top => slices.isEmpty ? null : slices.first;

  double get average => entryCount == 0 ? 0 : total / entryCount;
}

/// Computes per-category totals across [books], keeping only entries of [type].
///
/// Slices are sorted by total descending so the largest category leads the
/// legend, cards, and charts.
class CategoryAnalytics {
  const CategoryAnalytics();

  CategoryBreakdown breakdown(
    List<Book> books, {
    required ExpenseType type,
  }) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    // Remember the resolved category (label/color/icon) per id, including
    // custom categories denormalized onto expenses.
    final resolved = <String, ExpenseCategory>{};
    double grandTotal = 0;
    int entryCount = 0;

    for (final book in books) {
      for (final expense in book.expenses) {
        if (expense.type != type) {
          continue;
        }
        final category = ExpenseCategories.forExpense(expense);
        final id = category.id;
        resolved.putIfAbsent(id, () => category);
        totals[id] = (totals[id] ?? 0) + expense.amount;
        counts[id] = (counts[id] ?? 0) + 1;
        grandTotal += expense.amount;
        entryCount += 1;
      }
    }

    final slices = totals.entries.map((entry) {
      return CategorySlice(
        category: resolved[entry.key] ?? ExpenseCategories.byId(entry.key),
        total: entry.value,
        count: counts[entry.key] ?? 0,
        share: grandTotal == 0 ? 0 : entry.value / grandTotal,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return CategoryBreakdown(
      slices: slices,
      total: grandTotal,
      entryCount: entryCount,
    );
  }
}
