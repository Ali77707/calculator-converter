import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'unsaved_changes_guard.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key, this.hasUnsavedChanges = false});

  final bool hasUnsavedChanges;

  Future<void> _goHome(BuildContext context) async {
    if (hasUnsavedChanges) {
      final leave = await confirmUnsavedChanges(context);
      if (!leave || !context.mounted) return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _goHome(context),
      icon: const Icon(Icons.home_outlined, semanticLabel: 'Главное меню'),
    );
  }
}
