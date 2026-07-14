import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/connection_repository.dart';
import '../controllers/connection_controller.dart';
import 'shared_books_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Text(
                    _initials(user?.displayName ?? user?.email ?? ''),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Unnamed user',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '--'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Connect with others',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Consumer<ConnectionController>(
              builder: (context, controller, _) {
                final isLoading = controller.isLoading;
                final error = controller.errorMessage;
                final connections = controller.connections;

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                hintText: 'friend@example.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final success =
                                        await controller.sendRequest(_emailController.text.trim());
                                    if (success) {
                                      _emailController.clear();
                                    }
                                  },
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Connections',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : connections.isEmpty
                                ? const Center(child: Text('No connections yet.'))
                                : ListView.separated(
                                    itemCount: connections.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final record = connections[index];
                                      return _ConnectionTile(record: record);
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.record});

  final ConnectionRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<ConnectionController>();

    Widget trailing;
    if (record.isPending && record.isIncoming) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            tooltip: 'Accept',
            onPressed: () => controller.accept(record.userId),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
            tooltip: 'Decline',
            onPressed: () => controller.decline(record.userId),
          ),
        ],
      );
    } else if (record.isPending && record.isOutgoing) {
      trailing = const Text('Pending...', style: TextStyle(color: Colors.orange));
    } else if (record.isAccepted) {
      trailing = TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SharedBooksScreen(
                userId: record.userId,
                displayName: record.displayName.isNotEmpty
                    ? record.displayName
                    : record.email,
              ),
            ),
          );
        },
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('View'),
      );
    } else {
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Text(
              _initialFor(record.displayName, record.email),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.displayName.isNotEmpty ? record.displayName : record.email,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  record.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

String _initialFor(String displayName, String email) {
  final source = displayName.isNotEmpty
      ? displayName
      : email.isNotEmpty
          ? email
          : '?';
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}
