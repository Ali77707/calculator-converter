import '../models/service_order.dart';

abstract interface class ServiceOrderRepository {
  Future<List<ServiceOrder>> findAll({bool includeDeleted = false});
  Future<ServiceOrder?> findById(int id);
  Future<ServiceOrder> create(ServiceOrder order);
  Future<ServiceOrder> update(ServiceOrder order);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
}
