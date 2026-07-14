import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/book.dart';
import '../widgets/expense_tile.dart';
import '../../data/repositories/book_repository.dart';

class SharedBookDetailScreen extends StatelessWidget {
  const SharedBookDetailScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    required this.bookId,
  });

  final String ownerId;
  final String ownerName;
  final String bookId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = BookRepository();
    final currency = NumberFormat.currency(locale: 'en_IN', name: 'NPR', symbol: 'Rs ');

    return StreamBuilder<Book?>(
      stream: repository.watchBook(ownerId, bookId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final book = snapshot.data;
        if (book == null) {
          return Scaffold(
            appBar: AppBar(title: Text(ownerName)),
            body: Center(
              child: Text(
                'This book is no longer available.',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          );
        }

        final expenses = [...book.expenses]..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(book.title),
                Text(
                  'Shared by $ownerName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          body: Stack(
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
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                                Text(
                                  '${currency.format(book.totalSpent)} total',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ],
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
                              label: 'Expenses',
                              value: expenses.length.toString(),
                              icon: Icons.receipt_outlined,
                            ),
                            const SizedBox(width: 12),
                            _StatPill(
                              label: 'Average',
                              value: expenses.isEmpty
                                  ? currency.format(0)
                                  : currency.format(
                                      expenses.fold<double>(0, (sum, item) => sum + item.amount) /
                                          expenses.length,
                                    ),
                              icon: Icons.analytics_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (expenses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No expenses shared yet.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                        sliver: SliverList.separated(
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return ExpenseTile(expense: expense, onTap: null);
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
