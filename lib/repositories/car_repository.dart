import '../models/car.dart';
import '../models/car_query.dart';
import '../models/page_result.dart';

abstract interface class CarRepository {
  Future<PageResult<Car>> find(CarQuery query);
  Future<Car?> findById(int id);

  Future<List<Car>> findByOwner(int clientId);
  Future<Car> create(Car car);
  Future<Car> update(Car car);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
