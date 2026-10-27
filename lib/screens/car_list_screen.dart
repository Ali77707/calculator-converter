import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/car_query.dart';
import '../models/dictionaries.dart';
import '../repositories/brand_repository.dart';
import '../state/car_list_notifier.dart';
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

class CarListScreen extends StatefulWidget {
  const CarListScreen({super.key, required this.initialParams});

  final Map<String, String> initialParams;

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  late String _lastLocation;
  Map<int, String> _brandNames = const {};

  @override
  void initState() {
    super.initState();
    final query = CarQuery.fromParameters(widget.initialParams);
    _lastLocation = query.toLocation('/cars');

    context.read<CarListNotifier>().applyQuery(query);
    _loadBrandNames();
  }

  Future<void> _loadBrandNames() async {
    final repository = context.read<BrandRepository>();
    final brands = await repository.findAll(includeDeleted: true);
    if (!mounted) return;
    setState(() {
      _brandNames = {
        for (final brand in brands)
          brand.id: brand.isDeleted ? '${brand.name} (удалена)' : brand.name,
      };
    });
  }

  String _makeName(int id) => _brandNames[id] ?? makeName(id);

  @override
  void didUpdateWidget(covariant CarListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fromAddress = CarQuery.fromParameters(widget.initialParams);
    final notifier = context.read<CarListNotifier>();

    if (fromAddress != notifier.query) {
      _lastLocation = fromAddress.toLocation('/cars');
      notifier.applyQuery(fromAddress);
    }
  }

  void _onQueryChanged(CarQuery next, {required bool pushHistory}) {
    context.read<CarListNotifier>().applyQuery(next);
    if (!pushHistory) return;
    final location = next.toLocation('/cars');
    if (location == _lastLocation) return;
    _lastLocation = location;
    context.go(location);
  }

  void _reset() {
    _onQueryChanged(const CarQuery(), pushHistory: true);
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось выполнить действие: $error')),
    );
  }

  Future<void> _confirmDeleteSelected() async {
    final notifier = context.read<CarListNotifier>();
    final count = notifier.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Удалить выбранные ($count)?'),
        content: const Text(
          'Выбранные автомобили будут помечены как удалённые и уберутся из '
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
      await context.read<CarListNotifier>().deleteSelected();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmSoftDelete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text(
          '«${car.title}» будет помечен как удалённый и уйдёт из списка. '
          'Запись можно вернуть, включив показ удалённых.',
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
      await context.read<CarListNotifier>().softDelete(car.id);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmHardDelete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Стереть запись насовсем?'),
        content: Text(
          '«${car.title}» будет удалено без возможности восстановления. '
          'Отменить действие после подтверждения нельзя.',
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
      await context.read<CarListNotifier>().hardDelete(car.id);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _restore(Car car) async {
    try {
      await context.read<CarListNotifier>().restore(car.id);
    } catch (e) {
      _showError(e);
    }
  }

  List<Widget> _rowActions(BuildContext context, Car car) {
    return [
      if (!car.isDeleted)
        IconButton(
          tooltip: 'Изменить',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/cars/${car.id}/edit'),
        ),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: () => context.go('/cars/${car.id}'),
      ),
      if (car.isDeleted)
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: () => _restore(car),
        )
      else ...[
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmSoftDelete(car),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever_outlined),
          onPressed: () => _confirmHardDelete(car),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<CarListNotifier>();
    final query = notifier.query;

    return ListPageLayout(
      title: 'Автомобили',
      toolbar: SelectionToolbar(
        statusText: notifier.hasSelection
            ? 'Выбрано: ${notifier.selectedCount}'
            : 'Всего записей: ${notifier.result.total}',
        selectedCount: notifier.selectedCount,
        itemsAvailable: notifier.result.items.isNotEmpty,
        onSelectAllOnPage: () => context.read<CarListNotifier>().selectAll(
          notifier.result.items.map((c) => c.id),
          true,
        ),
        onClearSelection: () => context.read<CarListNotifier>().selectAll(
          notifier.selected.toList(),
          false,
        ),
        onDeleteSelected: _confirmDeleteSelected,
        deleteLabel: 'Удалить выбранные',
        trailing: FilledButton.icon(
          onPressed: () => context.go('/cars/new'),
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
              hint: 'Название или VIN',
              value: query.search,
              showClear: true,
              onValueChanged: (value) => _onQueryChanged(
                query.copyWith(search: value),
                pushHistory: true,
              ),
            ),
          ),
          FilterDropdown<NamedOption?>(
            label: 'Марка',
            value: _optionById(makes, query.makeId),
            items: optionItems(
              values: makes,
              labelOf: (o) => o.name,
              allLabel: 'Все марки',
            ),
            onChanged: (value) => _onQueryChanged(
              query.copyWith(makeId: value?.id),
              pushHistory: true,
            ),
          ),
          FilterDropdown<NamedOption?>(
            label: 'Тип кузова',
            value: _optionById(bodyTypes, query.bodyTypeId),
            items: optionItems(
              values: bodyTypes,
              labelOf: (o) => o.name,
              allLabel: 'Любой',
            ),
            onChanged: (value) => _onQueryChanged(
              query.copyWith(bodyTypeId: value?.id),
              pushHistory: true,
            ),
          ),
          FilterDropdown<String?>(
            label: 'Топливо',
            value: query.fuel,
            items: optionItems(
              values: fuelTypes,
              labelOf: (f) => f,
              allLabel: 'Любое',
            ),
            onChanged: (value) =>
                _onQueryChanged(query.copyWith(fuel: value), pushHistory: true),
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
        availableSizes: CarQuery.pageSizes,
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
    CarListNotifier notifier,
    ThemeData theme,
  ) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView(label: 'Загрузка списка автомобилей…');
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return EmptyView(
            message: 'Автомобили не найдены',
            hint: 'Измените поисковый запрос или сбросьте фильтры.',
            onReset: _reset,
          );
        }
        if (!isWide(context)) {
          return SingleChildScrollView(
            child: EntityCardList<Car>(
              items: notifier.result.items,
              idOf: (car) => car.id,
              selected: notifier.selected,
              onToggleSelect: (id) =>
                  context.read<CarListNotifier>().toggleSelection(id),
              buildCard: (context, car) => _buildCard(context, car, theme),
            ),
          );
        }
        return EntityTable<Car>(
          columns: _columns,
          items: notifier.result.items,
          idOf: (car) => car.id,
          selected: notifier.selected,
          onToggleSelect: (id) =>
              context.read<CarListNotifier>().toggleSelection(id),
          onSelectAll: (ids, selected) =>
              context.read<CarListNotifier>().selectAll(ids, selected),
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: _onSort,
          actions: (car) => _rowActions(context, car),
        );
    }
  }

  void _onSort(String field) {
    final notifier = context.read<CarListNotifier>();
    final query = notifier.query;
    final ascending = field == query.sortField ? !query.sortAscending : true;
    _onQueryChanged(
      query.copyWith(sortField: field, sortAscending: ascending),
      pushHistory: true,
    );
  }

  List<TableColumnSpec<Car>> get _columns => [
    TableColumnSpec<Car>(
      label: 'Название',
      sortField: 'title',
      build: (car) => Text(car.title),
    ),
    TableColumnSpec<Car>(
      label: 'VIN',
      sortField: 'vin',
      build: (car) =>
          Text(car.vin, style: const TextStyle(fontFamily: 'monospace')),
    ),
    TableColumnSpec<Car>(
      label: 'Год',
      sortField: 'year',
      numeric: true,
      build: (car) => Text('${car.year}'),
    ),
    TableColumnSpec<Car>(
      label: 'Пробег, км',
      sortField: 'mileage',
      numeric: true,
      build: (car) => Text('${car.mileage}'),
    ),
    TableColumnSpec<Car>(
      label: 'Марка',
      build: (car) => Text(_makeName(car.makeId)),
    ),
    TableColumnSpec<Car>(
      label: 'Кузов',
      build: (car) => Text(bodyTypeName(car.bodyTypeId)),
    ),
    TableColumnSpec<Car>(label: 'Топливо', build: (car) => Text(car.fuel)),
    TableColumnSpec<Car>(
      label: 'Стоимость, ₽',
      sortField: 'price',
      numeric: true,
      build: (car) => Text('${car.price}'),
    ),
  ];

  Widget _buildCard(BuildContext context, Car car, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(car.title, style: theme.textTheme.titleMedium),
              ),
              if (car.isDeleted)
                Chip(
                  label: const Text('Удалён'),
                  backgroundColor: theme.colorScheme.errorContainer,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('VIN ${car.vin}', style: theme.textTheme.bodySmall),
          Text(
            '${car.year} · ${_makeName(car.makeId)} · '
            '${bodyTypeName(car.bodyTypeId)} · ${car.fuel}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            '${car.mileage} км · ${car.price} ₽',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/cars/${car.id}'),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Открыть'),
              ),
              if (!car.isDeleted)
                TextButton.icon(
                  onPressed: () => context.go('/cars/${car.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить'),
                ),
              if (car.isDeleted)
                TextButton.icon(
                  onPressed: () => _restore(car),
                  icon: const Icon(Icons.restore),
                  label: const Text('Восстановить'),
                )
              else ...[
                TextButton.icon(
                  onPressed: () => _confirmSoftDelete(car),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmHardDelete(car),
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

NamedOption? _optionById(List<NamedOption> options, int? id) {
  if (id == null) return null;
  for (final option in options) {
    if (option.id == id) return option;
  }
  return null;
}
