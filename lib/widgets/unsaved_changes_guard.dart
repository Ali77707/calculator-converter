import 'package:flutter/material.dart';

Future<bool> confirmUnsavedChanges(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Несохранённые изменения'),
      content: const Text(
        'В форме есть несохранённые изменения. '
        'Выйти без сохранения?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Остаться'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Выйти'),
        ),
      ],
    ),
  );
  return leave ?? false;
}

class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    required this.child,
  });

  final bool hasChanges;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmUnsavedChanges(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
