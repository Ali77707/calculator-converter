import 'package:shared_preferences/shared_preferences.dart';

import '../models/car.dart';
import '../models/car_query.dart';
import '../models/page_result.dart';
import 'car_repository.dart';
import 'json_store.dart';
import 'seed_data.dart';

class InMemoryCarRepository implements CarRepository {
  InMemoryCarRepository({List<Car>? seed, SharedPreferences? prefs})
    : _store = JsonStore(prefs, 'cars_v1'),
      _cars = <Car>[] {
    final initial = seed ?? seedCars();
    _cars = prefs == null
        ? List.of(initial)
        : _store.read(Car.fromJson, initial);
    _nextId = _cars.fold<int>(1, (max, c) => c.id >= max ? c.id + 1 : max);
  }

  final JsonStore _store;
  late List<Car> _cars;
  late int _nextId;

  static const Duration _latency = Duration(milliseconds: 250);

  @override
  Future<PageResult<Car>> find(CarQuery q) async {
    await Future<void>.delayed(_latency);

    var rows = _cars.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (c) =>
                c.title.toLowerCase().contains(needle) ||
                c.vin.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.makeId != null) {
      rows = rows.where((c) => c.makeId == q.makeId).toList();
    }
    if (q.bodyTypeId != null) {
      rows = rows.where((c) => c.bodyTypeId == q.bodyTypeId).toList();
    }
    if (q.fuel != null) {
      rows = rows.where((c) => c.fuel == q.fuel).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((c) => c.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((c) => c.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final int result = switch (q.sortField) {
        'vin' => a.vin.toLowerCase().compareTo(b.vin.toLowerCase()),
        'year' => a.year.compareTo(b.year),
        'mileage' => a.mileage.compareTo(b.mileage),
        'price' => a.price.compareTo(b.price),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };

      if (result != 0) return q.sortAscending ? result : -result;
      return a.id.compareTo(b.id);
    });

    final total = rows.length;
    final totalPages = total == 0 ? 1 : (total / q.size).ceil();
    final page = q.page < 1 ? 1 : (q.page > totalPages ? totalPages : q.page);

    final from = (page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Car>[] : rows.sublist(from, to);

    return PageResult(items: items, page: page, size: q.size, total: total);
  }

  @override
  Future<List<Car>> findAll({bool includeDeleted = false}) async {
    return _cars
        .where((c) => includeDeleted || !c.isDeleted)
        .toList(growable: false);
  }

  @override
  Future<Car?> findById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (final car in _cars) {
      if (car.id == id) return car;
    }
    return null;
  }

  @override
  Future<int> countByMake(int makeId) async {
    return _cars.where((c) => c.makeId == makeId).length;
  }

  @override
  Future<List<Car>> findByOwner(int clientId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _cars
        .where((c) => !c.isDeleted && c.ownerIds.contains(clientId))
        .toList(growable: false);
  }

  @override
  Future<Car> create(Car car) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final created = Car(
      id: _nextId++,
      title: car.title,
      vin: car.vin,
      year: car.year,
      mileage: car.mileage,
      makeId: car.makeId,
      bodyTypeId: car.bodyTypeId,
      fuel: car.fuel,
      price: car.price,
      ownerIds: car.ownerIds,
    );
    _cars.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Car> update(Car car) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _cars.indexWhere((c) => c.id == car.id);
    if (i == -1) throw StateError('Автомобиль ${car.id} не найден');
    _cars[i] = car;
    await _persist();
    return car;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _cars.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Автомобиль $id не найден');
    _cars[i] = _cars[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _cars.removeWhere((c) => c.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _cars.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Автомобиль $id не найден');
    _cars[i] = _cars[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    var count = 0;
    for (final id in ids) {
      final i = _cars.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _cars[i] = _cars[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  Future<void> _persist() => _store.write(_cars, (c) => c.toJson());
}
