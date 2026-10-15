import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/page_layout.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageLayout(
      title: 'Страница не найдена',
      maxWidth: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.search_off, size: 72, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Ошибка 404',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Адрес «$location» не соответствует ни одному экрану приложения.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
            label: const Text('На главную'),
          ),
        ],
      ),
    );
  }
}
