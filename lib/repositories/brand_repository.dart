import '../models/brand.dart';

abstract interface class BrandRepository {
  Future<List<Brand>> findAll({bool includeDeleted = false});
  Future<Brand?> findById(int id);
  Future<Brand> create(Brand brand);
  Future<Brand> update(Brand brand);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
}
