import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;

  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;

  final void Function(List<int> ids, bool selected)? onSelectAll;

  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  @override
  Widget build(BuildContext context) {
    final ids = items.map(idOf).toList();
    final theme = Theme.of(context);

    final dataColumns = <DataColumn>[];

    int? sortColumnIndex;

    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      dataColumns.add(
        DataColumn(
          label: Text(column.label),
          numeric: column.numeric,
          onSort: column.sortField == null || onSort == null
              ? null
              : (_, __) => onSort!(column.sortField!),
        ),
      );
      if (column.sortField != null && column.sortField == sortField) {
        sortColumnIndex = i;
      }
    }

    if (actions != null) {
      dataColumns.add(const DataColumn(label: Text('Действия')));
    }

    final table = DataTable(
      headingRowColor: WidgetStatePropertyAll(
        theme.colorScheme.surfaceContainerHighest,
      ),
      columnSpacing: 24,
      columns: dataColumns,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showCheckboxColumn: onToggleSelect != null || onSelectAll != null,
      onSelectAll: onSelectAll == null
          ? null
          : (value) => onSelectAll!(ids, value ?? false),
      rows: items.map((item) {
        final id = idOf(item);
        final isSelected = selected.contains(id);
        final cells = <DataCell>[
          ...columns.map((c) => DataCell(c.build(item))),
          if (actions != null)
            DataCell(
              Row(mainAxisSize: MainAxisSize.min, children: actions!(item)),
            ),
        ];
        return DataRow(
          selected: isSelected,
          onSelectChanged: onToggleSelect == null
              ? null
              : (_) => onToggleSelect!(id),
          cells: cells,
        );
      }).toList(),
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : 0,
                ),
                child: table,
              ),
            ),
          );
        },
      ),
    );
  }
}
