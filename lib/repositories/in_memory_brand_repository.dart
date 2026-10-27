import 'package:shared_preferences/shared_preferences.dart';

import '../models/brand.dart';
import 'brand_repository.dart';
import 'json_store.dart';
import 'seed_data.dart';

class InMemoryBrandRepository implements BrandRepository {
  InMemoryBrandRepository({List<Brand>? seed, SharedPreferences? prefs})
    : _store = JsonStore(prefs, 'brands_v1'),
      _brands = <Brand>[] {
    final initial = seed ?? seedBrands();
    _brands = prefs == null
        ? List.of(initial)
        : _store.read(Brand.fromJson, initial);
    _nextId = _brands.fold<int>(1, (max, b) => b.id >= max ? b.id + 1 : max);
  }

  final JsonStore _store;
  late List<Brand> _brands;
  late int _nextId;

  @override
  Future<List<Brand>> findAll({bool includeDeleted = false}) async {
    return _brands
        .where((b) => includeDeleted || !b.isDeleted)
        .toList(growable: false);
  }

  @override
  Future<Brand?> findById(int id) async {
    for (final brand in _brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  @override
  Future<Brand> create(Brand brand) async {
    final created = Brand(
      id: _nextId++,
      name: brand.name,
      country: brand.country,
    );
    _brands.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Brand> update(Brand brand) async {
    final i = _brands.indexWhere((b) => b.id == brand.id);
    if (i == -1) throw StateError('Марка ${brand.id} не найдена');
    _brands[i] = brand;
    await _persist();
    return brand;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _brands.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Марка $id не найдена');
    _brands[i] = _brands[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _brands.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _brands.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Марка $id не найдена');
    _brands[i] = _brands[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  Future<void> _persist() => _store.write(_brands, (b) => b.toJson());
}
