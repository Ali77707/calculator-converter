import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/client_query.dart';
import '../models/dictionaries.dart';
import '../format.dart';
import '../state/client_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/debounced_text_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/filter_panel.dart';
import '../widgets/list_page_layout.dart';
import '../widgets/list_state_view.dart';
import '../widgets/pagination_bar.dart';

import '../widgets/responsive.dart';
import '../widgets/selection_toolbar.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key, required this.initialParams});

  final Map<String, String> initialParams;

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  late String _lastLocation;

  @override
  void initState() {
    super.initState();
    final query = ClientQuery.fromParameters(widget.initialParams);
    _lastLocation = query.toLocation('/clients');
    context.read<ClientListNotifier>().applyQuery(query);
  }

  @override
  void didUpdateWidget(covariant ClientListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fromAddress = ClientQuery.fromParameters(widget.initialParams);
    final notifier = context.read<ClientListNotifier>();
    if (fromAddress != notifier.query) {
      _lastLocation = fromAddress.toLocation('/clients');
      notifier.applyQuery(fromAddress);
    }
  }

  void _onQueryChanged(ClientQuery next, {required bool pushHistory}) {
    context.read<ClientListNotifier>().applyQuery(next);
    if (!pushHistory) return;
    final location = next.toLocation('/clients');
    if (location == _lastLocation) return;
    _lastLocation = location;
    context.go(location);
  }

  void _reset() {
    _onQueryChanged(const ClientQuery(), pushHistory: true);
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось выполнить действие: $error')),
    );
  }

  Future<void> _confirmDeleteSelected() async {
    final count = context.read<ClientListNotifier>().selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Удалить выбранные ($count)?'),
        content: const Text(
          'Выбранные клиенты будут помечены как удалённые и уберутся из '
          'списка. Восстановить их можно, включив показ удалённых.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ClientListNotifier>().deleteSelected();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmSoftDelete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text(
          '«${client.fullName}» будет помечен как удалённый и уйдёт из '
          'списка. Запись можно вернуть, включив показ удалённых.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ClientListNotifier>().softDelete(client.id);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmHardDelete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Стереть запись насовсем?'),
        content: Text(
          '«${client.fullName}» будет удалено без возможности '
          'восстановления. Отменить действие после подтверждения нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Стереть'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ClientListNotifier>().hardDelete(client.id);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _restore(Client client) async {
    try {
      await context.read<ClientListNotifier>().restore(client.id);
    } catch (e) {
      _showError(e);
    }
  }

  List<Widget> _rowActions(BuildContext context, Client client) {
    return [
      if (!client.isDeleted)
        IconButton(
          tooltip: 'Изменить',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/clients/${client.id}/edit'),
        ),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: () => context.go('/clients/${client.id}'),
      ),
      if (client.isDeleted)
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: () => _restore(client),
        )
      else ...[
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmSoftDelete(client),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever_outlined),
          onPressed: () => _confirmHardDelete(client),
        ),
      ],
    ];
  }

  void _onSort(String field) {
    final query = context.read<ClientListNotifier>().query;
    final ascending = field == query.sortField ? !query.sortAscending : true;
    _onQueryChanged(
      query.copyWith(sortField: field, sortAscending: ascending),
      pushHistory: true,
    );
  }

  static final List<TableColumnSpec<Client>> _columns = [
    TableColumnSpec<Client>(
      label: 'Фамилия',
      sortField: 'lastName',
      build: (client) => Text(client.lastName),
    ),
    TableColumnSpec<Client>(
      label: 'Имя',
      build: (client) => Text(client.firstName),
    ),
    TableColumnSpec<Client>(
      label: 'Отчество',
      build: (client) => Text(client.middleName),
    ),
    TableColumnSpec<Client>(
      label: 'Город',
      sortField: 'city',
      build: (client) => Text(client.city),
    ),
    TableColumnSpec<Client>(
      label: 'Телефон',
      sortField: 'phone',
      build: (client) => Text(client.phone),
    ),
    TableColumnSpec<Client>(
      label: 'E-mail',
      build: (client) => Text(client.email),
    ),
    TableColumnSpec<Client>(
      label: 'В автосервисе с',
      sortField: 'registeredAt',
      build: (client) => Text(ruDate(client.registeredAt)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<ClientListNotifier>();
    final query = notifier.query;

    return ListPageLayout(
      title: 'Клиенты',
      toolbar: SelectionToolbar(
        statusText: notifier.hasSelection
            ? 'Выбрано: ${notifier.selectedCount}'
            : 'Всего записей: ${notifier.result.total}',
        selectedCount: notifier.selectedCount,
        itemsAvailable: notifier.result.items.isNotEmpty,
        onSelectAllOnPage: () => context.read<ClientListNotifier>().selectAll(
          notifier.result.items.map((c) => c.id),
          true,
        ),
        onClearSelection: () => context.read<ClientListNotifier>().selectAll(
          notifier.selected.toList(),
          false,
        ),
        onDeleteSelected: _confirmDeleteSelected,
        deleteLabel: 'Удалить выбранные',
        trailing: FilledButton.icon(
          onPressed: () => context.go('/clients/new'),
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
        ),
      ),
      filters: FilterPanel(
        onReset: _reset,
        children: [
          SizedBox(
            width: 280,
            child: DebouncedTextField(
              label: 'Поиск',
              hint: 'Фамилия или город',
              value: query.search,
              showClear: true,
              onValueChanged: (value) => _onQueryChanged(
                query.copyWith(search: value),
                pushHistory: true,
              ),
            ),
          ),
          FilterDropdown<String?>(
            label: 'Город',
            value: query.city,
            items: optionItems(
              values: clientCities,
              labelOf: (city) => city,
              allLabel: 'Все города',
            ),
            onChanged: (value) =>
                _onQueryChanged(query.copyWith(city: value), pushHistory: true),
          ),
          SizedBox(
            width: 140,
            child: DebouncedTextField(
              label: 'Год от',
              value: '${query.yearFrom ?? ''}',
              keyboardType: TextInputType.number,
              onValueChanged: (value) => _onQueryChanged(
                query.copyWith(yearFrom: int.tryParse(value)),
                pushHistory: true,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: DebouncedTextField(
              label: 'Год до',
              value: '${query.yearTo ?? ''}',
              keyboardType: TextInputType.number,
              onValueChanged: (value) => _onQueryChanged(
                query.copyWith(yearTo: int.tryParse(value)),
                pushHistory: true,
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Switch(
                  value: query.includeDeleted,
                  onChanged: (value) => _onQueryChanged(
                    query.copyWith(includeDeleted: value),
                    pushHistory: true,
                  ),
                ),
                const SizedBox(width: 4),
                const Flexible(child: Text('Показывать удалённые')),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(context, notifier, theme),
      pagination: PaginationBar(
        page: notifier.result.page,
        totalPages: notifier.result.totalPages,
        total: notifier.result.total,
        size: query.size,
        availableSizes: ClientQuery.pageSizes,
        firstItemIndex: notifier.result.firstItemIndex,
        lastItemIndex: notifier.result.lastItemIndex,
        onPageChanged: (page) =>
            _onQueryChanged(query.copyWith(page: page), pushHistory: true),
        onSizeChanged: (size) =>
            _onQueryChanged(query.copyWith(size: size), pushHistory: true),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClientListNotifier notifier,
    ThemeData theme,
  ) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView(label: 'Загрузка списка клиентов…');
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return EmptyView(
            message: 'Клиенты не найдены',
            hint: 'Измените поисковый запрос или сбросьте фильтры.',
            onReset: _reset,
          );
        }
        if (!isWide(context)) {
          return SingleChildScrollView(
            child: EntityCardList<Client>(
              items: notifier.result.items,
              idOf: (client) => client.id,
              selected: notifier.selected,
              onToggleSelect: (id) =>
                  context.read<ClientListNotifier>().toggleSelection(id),
              buildCard: (context, client) =>
                  _buildCard(context, client, theme),
            ),
          );
        }
        return EntityTable<Client>(
          columns: _columns,
          items: notifier.result.items,
          idOf: (client) => client.id,
          selected: notifier.selected,
          onToggleSelect: (id) =>
              context.read<ClientListNotifier>().toggleSelection(id),
          onSelectAll: (ids, selected) =>
              context.read<ClientListNotifier>().selectAll(ids, selected),
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: _onSort,
          actions: (client) => _rowActions(context, client),
        );
    }
  }

  Widget _buildCard(BuildContext context, Client client, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  client.fullName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (client.isDeleted)
                Chip(
                  label: const Text('Удалён'),
                  backgroundColor: theme.colorScheme.errorContainer,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${client.city} · ${client.phone}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(client.email, style: theme.textTheme.bodySmall),
          Text(
            'В автосервисе с ${ruDate(client.registeredAt)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/clients/${client.id}'),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Открыть'),
              ),
              if (!client.isDeleted)
                TextButton.icon(
                  onPressed: () => context.go('/clients/${client.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить'),
                ),
              if (client.isDeleted)
                TextButton.icon(
                  onPressed: () => _restore(client),
                  icon: const Icon(Icons.restore),
                  label: const Text('Восстановить'),
                )
              else ...[
                TextButton.icon(
                  onPressed: () => _confirmSoftDelete(client),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmHardDelete(client),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Стереть'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
