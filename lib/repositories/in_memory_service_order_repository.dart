import 'package:shared_preferences/shared_preferences.dart';

import '../models/service_order.dart';
import 'json_store.dart';
import 'seed_data.dart';
import 'service_order_repository.dart';

class InMemoryServiceOrderRepository implements ServiceOrderRepository {
  InMemoryServiceOrderRepository({
    List<ServiceOrder>? seed,
    SharedPreferences? prefs,
  }) : _store = JsonStore(prefs, 'service_orders_v2'),
       _orders = <ServiceOrder>[] {
    final initial = seed ?? seedServiceOrders();
    _orders = prefs == null
        ? List.of(initial)
        : _store.read(ServiceOrder.fromJson, initial);
    _nextId = _orders.fold<int>(1, (max, o) => o.id >= max ? o.id + 1 : max);
  }

  final JsonStore _store;
  late List<ServiceOrder> _orders;
  late int _nextId;

  @override
  Future<List<ServiceOrder>> findAll({bool includeDeleted = false}) async {
    final rows = _orders
        .where((o) => includeDeleted || !o.isDeleted)
        .toList(growable: false);
    return rows;
  }

  @override
  Future<ServiceOrder?> findById(int id) async {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<ServiceOrder> create(ServiceOrder order) async {
    final created = ServiceOrder(
      id: _nextId++,
      number: order.number,
      carId: order.carId,
      clientId: order.clientId,
      description: order.description,
      status: order.status,
      price: order.price,
      createdAt: order.createdAt,
    );
    _orders.add(created);
    await _persist();
    return created;
  }

  @override
  Future<ServiceOrder> update(ServiceOrder order) async {
    final i = _orders.indexWhere((o) => o.id == order.id);
    if (i == -1) throw StateError('Заказ ${order.id} не найден');
    _orders[i] = order;
    await _persist();
    return order;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i == -1) throw StateError('Заказ $id не найден');
    _orders[i] = _orders[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _orders.removeWhere((o) => o.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i == -1) throw StateError('Заказ $id не найден');
    _orders[i] = _orders[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  Future<void> _persist() => _store.write(_orders, (o) => o.toJson());
}
