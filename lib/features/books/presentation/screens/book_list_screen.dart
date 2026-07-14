import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/book.dart';
import '../controllers/book_controller.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  Future<void> _refresh(BuildContext context) {
    return context.read<BookController>().refresh();
  }

  void _openCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddBookSheet(),
    );
  }

  void _openDetails(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(bookId: book.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Consumer<BookController>(
              builder: (context, controller, _) {
                final auth = context.watch<AuthController>();
                final user = auth.user;
                final displayName = (user?.displayName ?? '').trim();
                final firstName = displayName.isEmpty ? 'there' : displayName.split(' ').first;
                final photoUrl = user?.photoURL;
                final initials = displayName.isEmpty
                    ? 'U'
                    : displayName
                        .split(RegExp(r'\s+'))
                        .where((part) => part.isNotEmpty)
                        .take(2)
                        .map((part) => part.substring(0, 1).toUpperCase())
                        .join();

                final books = controller.books;
                final isLoading = controller.isLoading && books.isEmpty;

                return RefreshIndicator.adaptive(
                  color: theme.colorScheme.primary,
                  onRefresh: () => _refresh(context),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello, $firstName',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Track your spending with ease',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (books.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: IconButton(
                                        tooltip: 'Analytics',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const AnalyticsScreen(),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.insights_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  PopupMenuButton<_AccountAction>(
                                    tooltip: 'Account options',
                                    onSelected: (action) {
                                      final authController = context.read<AuthController>();
                                      final navigator = Navigator.of(context);
                                      switch (action) {
                                        case _AccountAction.signOut:
                                          Future.microtask(() => authController.signOut());
                                          break;
                                        case _AccountAction.profile:
                                          Future.microtask(() {
                                            if (!mounted) {
                                              return;
                                            }
                                            navigator.push(
                                              MaterialPageRoute(
                                                builder: (_) => const ProfileScreen(),
                                              ),
                                            );
                                          });
                                          break;
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: _AccountAction.profile,
                                        child: Text('Open profile'),
                                      ),
                                      PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: _AccountAction.signOut,
                                        child: Text('Sign out'),
                                      ),
                                    ],
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                      child: photoUrl == null
                                          ? Text(
                                              initials,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Books',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppLoadingIndicator(
                            message: 'Loading your books...',
                          ),
                        )
                      else if (books.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            title: 'No books yet',
                            message:
                                'Create your first book to start grouping expenses by category, trip, or project.',
                            icon: Icons.auto_stories_outlined,
                            action: ElevatedButton.icon(
                              onPressed: _openCreateSheet,
                              icon: const Icon(Icons.add),
                              label: const Text('Create a book'),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          sliver: SliverList.separated(
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: BookCard(
                                  book: book,
                                  onTap: () => _openDetails(book),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Book'),
      ),
    );
  }
}

enum _AccountAction { profile, signOut }
