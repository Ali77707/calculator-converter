class ClientQuery {
  final String search;
  final String? city;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ClientQuery({
    this.search = '',
    this.city,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const List<String> sortFields = [
    'lastName',
    'city',
    'phone',
    'registeredAt',
  ];

  static const List<int> pageSizes = [10, 25, 50];

  ClientQuery copyWith({
    String? search,
    Object? city = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ClientQuery(
      search: search ?? this.search,
      city: city == _unset ? this.city : city as String?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,

      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory ClientQuery.fromParameters(Map<String, String> parameters) {
    final sort = _parseSort(parameters['sort']);
    final size = int.tryParse(parameters['size'] ?? '') ?? 10;
    return ClientQuery(
      search: parameters['search'] ?? '',
      city: _emptyToNull(parameters['city']),
      yearFrom: int.tryParse(parameters['yearFrom'] ?? ''),
      yearTo: int.tryParse(parameters['yearTo'] ?? ''),
      sortField: sort.$1,
      sortAscending: sort.$2,
      page: int.tryParse(parameters['page'] ?? '') ?? 1,
      size: ClientQuery.pageSizes.contains(size) ? size : 10,
      includeDeleted: parameters['deleted'] == 'true',
    );
  }

  Map<String, String> toParameters() {
    final parameters = <String, String>{};
    if (search.isNotEmpty) parameters['search'] = search;
    if (city != null) parameters['city'] = city!;
    if (yearFrom != null) parameters['yearFrom'] = '$yearFrom';
    if (yearTo != null) parameters['yearTo'] = '$yearTo';
    if (sortField != 'lastName' || !sortAscending) {
      parameters['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) parameters['page'] = '$page';
    if (size != 10) parameters['size'] = '$size';
    if (includeDeleted) parameters['deleted'] = 'true';
    return parameters;
  }

  String toLocation(String basePath) {
    final parameters = toParameters();
    if (parameters.isEmpty) return basePath;
    return Uri(path: basePath, queryParameters: parameters).toString();
  }

  @override
  bool operator ==(Object other) =>
      other is ClientQuery && other.toLocation('') == toLocation('');

  @override
  int get hashCode => toLocation('').hashCode;

  @override
  String toString() => 'ClientQuery${toLocation('')}';
}

const Object _unset = Object();

String? _emptyToNull(String? value) =>
    (value == null || value.isEmpty) ? null : value;

(String, bool) _parseSort(String? raw) {
  final comma = raw?.lastIndexOf(',') ?? -1;
  if (comma <= 0) return ('lastName', true);
  final field = raw!.substring(0, comma);
  if (!ClientQuery.sortFields.contains(field)) return ('lastName', true);
  final descending = raw.substring(comma + 1).trim().toLowerCase() == 'desc';
  return (field, !descending);
}
