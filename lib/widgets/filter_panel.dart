import 'package:flutter/material.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.children,
    this.onReset,
    this.trailing,
  });

  final List<Widget> children;
  final VoidCallback? onReset;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            ...children,
            if (onReset != null)
              OutlinedButton(onPressed: onReset, child: const Text('Сбросить')),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
