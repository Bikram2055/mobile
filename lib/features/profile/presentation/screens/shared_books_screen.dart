import 'package:flutter/material.dart';

import '../../../books/data/models/book.dart';
import '../../../books/data/repositories/book_repository.dart';
import '../../../books/presentation/widgets/book_card.dart';
import '../../../books/presentation/screens/shared_book_detail_screen.dart';

class SharedBooksScreen extends StatelessWidget {
  const SharedBooksScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;

  void _openBook(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedBookDetailScreen(
          ownerId: userId,
          ownerName: displayName,
          bookId: book.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = BookRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text("$displayName's books"),
      ),
      body: StreamBuilder<List<Book>>(
        stream: repository.watchBooks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load books right now.'),
            );
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return Center(
              child: Text(
                '$displayName has not added any books yet.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                onTap: () => _openBook(context, book),
              );
            },
          );
        },
      ),
    );
  }
}
