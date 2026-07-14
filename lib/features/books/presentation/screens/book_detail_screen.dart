import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../data/models/book.dart';
import '../../data/models/expense.dart';
import '../controllers/book_controller.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/expense_tile.dart';
import '../../utils/book_exporter.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  void _addExpense(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseSheet(bookId: bookId),
    );
  }

  void _editExpense(BuildContext context, Book book, Expense expense) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseSheet(
        bookId: book.id,
        expense: expense,
      ),
    );
  }

  void _addIncome(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseSheet(
        bookId: bookId,
        isIncome: true,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete book'),
          content: Text(
            'Are you sure you want to delete "${book.title}"? This will remove ${book.expenseCount} expense${book.expenseCount == 1 ? '' : 's'} permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<BookController>();

    final success = await controller.deleteBook(book.id);

    if (!navigator.mounted) {
      return;
    }

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('"${book.title}" has been deleted.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to delete the book.'),
        ),
      );
    }
  }

  Future<void> _exportBook(
    BuildContext context,
    Book book,
    _ExportFormat format,
  ) async {
    final exporter = BookExporter();
    final messenger = ScaffoldMessenger.of(context);
    final normalizedTitle = book.title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final filename =
        '${normalizedTitle.isEmpty ? 'book' : normalizedTitle}.${format == _ExportFormat.csv ? 'csv' : 'pdf'}';

    try {
      late final XFile file;
      if (format == _ExportFormat.csv) {
        final bytes = exporter.toCsvBytes(book);
        file = XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: filename,
        );
      } else {
        final bytes = await exporter.toPdfBytes(book);
        file = XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: filename,
        );
      }

      await Share.shareXFiles([file], text: 'Export from ${book.title}');
    } catch (error, stackTrace) {
      debugPrint('Failed to export book: $error\n$stackTrace');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not export ${book.title}. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<BookController>(
        builder: (context, controller, _) {
          final book = controller.bookById(bookId);
          final isLoading = controller.isLoading && book == null;

          if (isLoading) {
            return const Center(
              child: AppLoadingIndicator(),
            );
          }

          if (book == null) {
            return EmptyState(
              title: 'Book unavailable',
              message: 'We could not find this book. It may have been removed.',
              icon: Icons.error_outline,
              action: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go back'),
              ),
            );
          }

          final expenses = [...book.expenses]..sort((a, b) => b.date.compareTo(a.date));
          final incomeTotal = expenses
              .where((e) => e.isIncome)
              .fold<double>(0, (sum, item) => sum + item.amount);
          final expenseTotal = expenses
              .where((e) => e.isExpense)
              .fold<double>(0, (sum, item) => sum + item.amount);
          final currency = NumberFormat.currency(
            locale: 'en_IN',
            name: 'NPR',
            symbol: 'Rs ',
          );

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.14),
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      foregroundColor: theme.colorScheme.onSurface,
                      pinned: true,
                      expandedHeight: 220,
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnalyticsScreen(bookId: book.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.insights_rounded),
                          tooltip: 'Analytics',
                        ),
                        PopupMenuButton<_ExportFormat>(
                          icon: const Icon(Icons.file_download_outlined),
                          tooltip: 'Export book',
                          onSelected: (format) => _exportBook(context, book, format),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _ExportFormat.csv,
                              child: Text('Export as CSV'),
                            ),
                            PopupMenuItem(
                              value: _ExportFormat.pdf,
                              child: Text('Export as PDF'),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: controller.isSaving
                              ? null
                              : () => _confirmDelete(context, book),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete book',
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Hero(
                            tag: 'book-${book.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.auto_stories,
                                      color: theme.colorScheme.onPrimary,
                                      size: 34,
                                    ),
                                    const Spacer(),
                                    Text(
                                      book.title,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Income\n${currency.format(incomeTotal)}',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: Colors.green.shade50,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Spent\n${currency.format(expenseTotal)}',
                                            textAlign: TextAlign.right,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Row(
                          children: [
                            _StatPill(
                              label: 'Income total',
                              value: currency.format(incomeTotal),
                              icon: Icons.trending_up,
                              valueColor: Colors.green.shade700,
                            ),
                            const SizedBox(width: 12),
                            _StatPill(
                              label: 'Expense total',
                              value: currency.format(expenseTotal),
                              icon: Icons.trending_down,
                              valueColor: theme.colorScheme.error,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (expenses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          title: 'No expenses yet',
                          message: 'Add your first expense to keep track of this book.',
                          icon: Icons.receipt_long,
                          action: ElevatedButton.icon(
                            onPressed: () => _addExpense(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add an expense'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                        sliver: SliverList.separated(
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return ExpenseTile(
                              expense: expense,
                              onTap: () => _editExpense(context, book, expense),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            FloatingActionButton.extended(
              heroTag: 'income-$bookId',
              onPressed: () => _addIncome(context),
              icon: const Icon(Icons.attach_money_outlined),
              label: const Text('Add income'),
            ),
            const Spacer(),
            FloatingActionButton.extended(
              heroTag: 'expense-$bookId',
              onPressed: () => _addExpense(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExportFormat { csv, pdf }
