import 'package:flutter/material.dart';

class EntityCardList<T> extends StatelessWidget {
  const EntityCardList({
    super.key,
    required this.items,
    required this.idOf,
    required this.buildCard,
    this.selected = const {},
    this.onToggleSelect,
  });

  final List<T> items;
  final int Function(T item) idOf;
  final Widget Function(BuildContext context, T item) buildCard;

  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Builder(
            builder: (context) {
              final id = idOf(item);
              final isSelected = selected.contains(id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onToggleSelect == null
                        ? null
                        : () => onToggleSelect!(id),
                    child: buildCard(context, item),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
