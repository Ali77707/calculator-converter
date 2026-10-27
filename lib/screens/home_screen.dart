import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/page_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Автосервис',
      maxWidth: 640,
      showHomeButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => context.go('/cars'),
            child: const Text('Автомобили'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/clients'),
            child: const Text('Клиенты'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/brands'),
            child: const Text('Марки'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/orders'),
            child: const Text('Заказы'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/loyalty-cards'),
            child: const Text('Карты лояльности'),
          ),
        ],
      ),
    );
  }
}
