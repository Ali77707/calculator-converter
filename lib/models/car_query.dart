class CarQuery {
  final String search;
  final int? makeId;
  final int? bodyTypeId;
  final String? fuel;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const CarQuery({
    this.search = '',
    this.makeId,
    this.bodyTypeId,
    this.fuel,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const List<String> sortFields = [
    'title',
    'vin',
    'year',
    'mileage',
    'price',
  ];

  static const List<int> pageSizes = [10, 25, 50];

  CarQuery copyWith({
    String? search,
    Object? makeId = _unset,
    Object? bodyTypeId = _unset,
    Object? fuel = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CarQuery(
      search: search ?? this.search,
      makeId: makeId == _unset ? this.makeId : makeId as int?,
      bodyTypeId: bodyTypeId == _unset ? this.bodyTypeId : bodyTypeId as int?,
      fuel: fuel == _unset ? this.fuel : fuel as String?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,

      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory CarQuery.fromParameters(Map<String, String> parameters) {
    final sort = _parseSort(parameters['sort']);
    final size = int.tryParse(parameters['size'] ?? '') ?? 10;
    return CarQuery(
      search: parameters['search'] ?? '',
      makeId: int.tryParse(parameters['makeId'] ?? ''),
      bodyTypeId: int.tryParse(parameters['bodyTypeId'] ?? ''),
      fuel: _emptyToNull(parameters['fuel']),
      yearFrom: int.tryParse(parameters['yearFrom'] ?? ''),
      yearTo: int.tryParse(parameters['yearTo'] ?? ''),
      sortField: sort.$1,
      sortAscending: sort.$2,
      page: int.tryParse(parameters['page'] ?? '') ?? 1,
      size: CarQuery.pageSizes.contains(size) ? size : 10,
      includeDeleted: parameters['deleted'] == 'true',
    );
  }

  Map<String, String> toParameters() {
    final parameters = <String, String>{};
    if (search.isNotEmpty) parameters['search'] = search;
    if (makeId != null) parameters['makeId'] = '$makeId';
    if (bodyTypeId != null) parameters['bodyTypeId'] = '$bodyTypeId';
    if (fuel != null) parameters['fuel'] = fuel!;
    if (yearFrom != null) parameters['yearFrom'] = '$yearFrom';
    if (yearTo != null) parameters['yearTo'] = '$yearTo';
    if (sortField != 'title' || !sortAscending) {
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
      other is CarQuery && other.toLocation('') == toLocation('');

  @override
  int get hashCode => toLocation('').hashCode;

  @override
  String toString() => 'CarQuery${toLocation('')}';
}

const Object _unset = Object();

String? _emptyToNull(String? value) =>
    (value == null || value.isEmpty) ? null : value;

(String, bool) _parseSort(String? raw) {
  final comma = raw?.lastIndexOf(',') ?? -1;
  if (comma <= 0) return ('title', true);
  final field = raw!.substring(0, comma);
  if (!CarQuery.sortFields.contains(field)) return ('title', true);
  final descending = raw.substring(comma + 1).trim().toLowerCase() == 'desc';
  return (field, !descending);
}
