import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'list_page_layout.dart';
import 'list_state_view.dart';
import 'pagination_bar.dart';

class CrudListPage<T> extends StatefulWidget {
  const CrudListPage({
    super.key,
    required this.title,
    required this.addLocation,
    required this.searchHint,
    required this.load,
    required this.idOf,
    required this.titleOf,
    required this.subtitleOf,
    required this.searchText,
    required this.isDeleted,
    required this.detailLocation,
    required this.editLocation,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
    this.emptyMessage = 'Записей пока нет',
    this.filterLabel,
    this.filterOptions = const [],
    this.filterOf,
  });

  final String title;
  final String addLocation;
  final String searchHint;
  final Future<List<T>> Function() load;
  final int Function(T) idOf;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final String Function(T) searchText;
  final bool Function(T) isDeleted;
  final String Function(T) detailLocation;
  final String Function(T) editLocation;
  final Future<void> Function(int id) onSoftDelete;
  final Future<void> Function(int id) onHardDelete;
  final Future<void> Function(int id) onRestore;
  final String emptyMessage;
  final String? filterLabel;
  final List<String> filterOptions;
  final String Function(T item)? filterOf;

  @override
  State<CrudListPage<T>> createState() => _CrudListPageState<T>();
}

class _CrudListPageState<T> extends State<CrudListPage<T>> {
  static const _pageSizes = [10, 25, 50];

  List<T> _items = const [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _filterValue;
  bool _showDeleted = false;
  bool _sortAscending = true;
  int _page = 1;
  int _size = 10;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.load();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  List<T> get _filtered {
    final needle = _search.trim().toLowerCase();
    final rows = _items
        .where((item) => _showDeleted || !widget.isDeleted(item))
        .where(
          (item) =>
              needle.isEmpty ||
              widget.searchText(item).toLowerCase().contains(needle),
        )
        .where(
          (item) =>
              _filterValue == null ||
              widget.filterOf?.call(item) == _filterValue,
        )
        .toList();
    rows.sort((a, b) {
      final result = widget
          .titleOf(a)
          .toLowerCase()
          .compareTo(widget.titleOf(b).toLowerCase());
      return _sortAscending ? result : -result;
    });
    return rows;
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось выполнить действие: $error')),
      );
    }
  }

  Future<void> _softDelete(T item) async {
    final ok = await _confirm(
      'Удалить запись?',
      'Запись будет скрыта из списка, её можно восстановить.',
    );
    if (!ok) return;
    await _runAction(() => widget.onSoftDelete(widget.idOf(item)));
  }

  Future<void> _hardDelete(T item) async {
    final ok = await _confirm(
      'Удалить навсегда?',
      'Запись будет удалена без возможности восстановления.',
    );
    if (!ok) return;
    await _runAction(() => widget.onHardDelete(widget.idOf(item)));
  }

  Future<void> _restore(T item) async {
    await _runAction(() => widget.onRestore(widget.idOf(item)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _filtered;
    final total = rows.length;
    final totalPages = total == 0 ? 1 : (total / _size).ceil();
    final page = _page > totalPages ? totalPages : _page;
    final from = (page - 1) * _size;
    final to = from + _size > total ? total : from + _size;
    final items = from >= total ? <T>[] : rows.sublist(from, to);

    return ListPageLayout(
      title: widget.title,
      toolbar: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Всего записей: $total', style: theme.textTheme.bodyMedium),
          FilterChip(
            label: const Text('Показывать удалённые'),
            selected: _showDeleted,
            onSelected: (value) {
              setState(() {
                _showDeleted = value;
                _page = 1;
              });
            },
          ),
          IconButton.outlined(
            tooltip: _sortAscending
                ? 'Сортировка по возрастанию'
                : 'Сортировка по убыванию',
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go(widget.addLocation),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
        ],
      ),
      filters: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(() {
                          _search = '';
                          _page = 1;
                        }),
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _page = 1;
                });
              },
            ),
          ),
          if (widget.filterOf != null && widget.filterOptions.isNotEmpty)
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_filterValue),
                initialValue: _filterValue,
                decoration: InputDecoration(
                  labelText: widget.filterLabel ?? 'Фильтр',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final option in widget.filterOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterValue = value;
                    _page = 1;
                  });
                },
              ),
            ),
          if (_filterValue != null)
            TextButton(
              onPressed: () => setState(() {
                _filterValue = null;
                _page = 1;
              }),
              child: const Text('Сбросить фильтр'),
            ),
        ],
      ),
      body: _buildBody(items),
      pagination: PaginationBar(
        page: page,
        totalPages: totalPages,
        total: total,
        size: _size,
        availableSizes: _pageSizes,
        firstItemIndex: total == 0 ? 0 : from + 1,
        lastItemIndex: to,
        onPageChanged: (value) => setState(() => _page = value),
        onSizeChanged: (value) => setState(() {
          _size = value;
          _page = 1;
        }),
      ),
    );
  }

  Widget _buildBody(List<T> items) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _reload);
    if (items.isEmpty) {
      return EmptyView(
        message: widget.emptyMessage,
        hint: _search.isEmpty
            ? 'Добавьте первую запись с помощью кнопки выше.'
            : 'Измените поисковый запрос или сбросьте фильтры.',
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final deleted = widget.isDeleted(item);
        return _CrudCard(
          title: widget.titleOf(item),
          subtitle: widget.subtitleOf(item),
          deleted: deleted,
          onOpen: () => context.go(widget.detailLocation(item)),
          onEdit: deleted ? null : () => context.go(widget.editLocation(item)),
          onSoftDelete: deleted ? null : () => _softDelete(item),
          onRestore: deleted ? () => _restore(item) : null,
          onHardDelete: () => _hardDelete(item),
        );
      },
    );
  }
}

class _CrudCard extends StatelessWidget {
  const _CrudCard({
    required this.title,
    required this.subtitle,
    required this.deleted,
    required this.onOpen,
    required this.onEdit,
    required this.onSoftDelete,
    required this.onRestore,
    required this.onHardDelete,
  });

  final String title;
  final String subtitle;
  final bool deleted;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onSoftDelete;
  final VoidCallback? onRestore;
  final VoidCallback onHardDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: deleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (deleted)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(label: Text('Удалено')),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'soft':
                      onSoftDelete?.call();
                      break;
                    case 'restore':
                      onRestore?.call();
                      break;
                    case 'hard':
                      onHardDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Изменить')),
                  if (onSoftDelete != null)
                    const PopupMenuItem(value: 'soft', child: Text('Удалить')),
                  if (onRestore != null)
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Восстановить'),
                    ),
                  const PopupMenuItem(
                    value: 'hard',
                    child: Text('Удалить навсегда'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
