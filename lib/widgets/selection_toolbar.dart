import 'package:flutter/material.dart';

class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    super.key,
    required this.statusText,
    required this.selectedCount,
    required this.itemsAvailable,
    required this.onSelectAllOnPage,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.deleteLabel,
    this.trailing,
  });

  final String statusText;
  final int selectedCount;
  final bool itemsAvailable;
  final VoidCallback onSelectAllOnPage;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final String deleteLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedCount > 0;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasSelection
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasSelection ? theme.colorScheme.onPrimaryContainer : null,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: itemsAvailable ? onSelectAllOnPage : null,
          child: const Text('Отметить страницу'),
        ),
        if (hasSelection)
          TextButton(
            onPressed: onClearSelection,
            child: const Text('Снять отметки'),
          ),
        if (hasSelection)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            onPressed: onDeleteSelected,
            child: Text(deleteLabel),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
