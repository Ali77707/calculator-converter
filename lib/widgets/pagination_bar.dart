import 'package:flutter/material.dart';



class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.availableSizes,
    required this.firstItemIndex,
    required this.lastItemIndex,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  final int page;
  final int totalPages;
  final int total;
  final int size;
  final List<int> availableSizes;
  final int firstItemIndex;
  final int lastItemIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPrevious = page > 1;
    final canNext = page < totalPages;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton.outlined(
            onPressed: canPrevious ? () => onPageChanged(1) : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton.outlined(
            onPressed: canPrevious ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            total == 0
                ? 'Страница $page из $totalPages · записей нет'
                : 'Страница $page из $totalPages · '
                      'показано $firstItemIndex–$lastItemIndex из $total',
            style: theme.textTheme.bodyMedium,
          ),
          IconButton.outlined(
            onPressed: canNext ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton.outlined(
            onPressed: canNext ? () => onPageChanged(totalPages) : null,
            icon: const Icon(Icons.last_page),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: size,
            isDense: true,
            items: [
              for (final s in availableSizes)
                DropdownMenuItem(value: s, child: Text('$s на странице')),
            ],
            onChanged: (value) {
              if (value != null && value != size) onSizeChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
