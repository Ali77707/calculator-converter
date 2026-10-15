import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/page_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageLayout(
      title: 'Главная',
      maxWidth: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Калькулятор и конвертер валют',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите раздел.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go('/calculator'),
            label: const Text('Калькулятор'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/converter'),
            label: const Text('Конвертер валют'),
          ),
        ],
      ),
    );
  }
}
