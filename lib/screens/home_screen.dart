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
        ],
      ),
    );
  }
}
