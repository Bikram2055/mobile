import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/books/data/repositories/book_repository.dart';
import '../features/books/presentation/controllers/book_controller.dart';
import '../features/books/presentation/screens/book_list_screen.dart';
import '../features/profile/data/connection_repository.dart';
import '../features/profile/presentation/controllers/connection_controller.dart';
import 'theme.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(
            repository: AuthRepository(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, BookController>(
          create: (_) => BookController(repository: BookRepository()),
          update: (_, auth, bookController) {
            final controller = bookController ?? BookController(repository: BookRepository());
            controller.attachUser(auth.user?.uid);
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, ConnectionController>(
          create: (_) => ConnectionController(repository: ConnectionRepository()),
          update: (_, auth, connectionController) {
            final controller =
                connectionController ?? ConnectionController(repository: ConnectionRepository());
            controller.attachUser(auth.user?.uid);
            return controller;
          },
        ),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          Widget home;
          if (auth.isInitialising) {
            home = const _SplashScreen();
          } else if (auth.user == null) {
            home = const SignInScreen();
          } else {
            home = const BookListScreen();
          }

          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: home,
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
