import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/client.dart';
import '../models/service_order.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import '../widgets/crud_list_page.dart';

class ServiceOrderListScreen extends StatelessWidget {
  const ServiceOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudListPage<_OrderRow>(
      title: 'Заказы',
      addLocation: '/orders/new',
      searchHint: 'Поиск по номеру, клиенту, автомобилю или статусу',
      load: () async {
        final orderRepository = context.read<ServiceOrderRepository>();
        final clientRepository = context.read<ClientRepository>();
        final carRepository = context.read<CarRepository>();
        final orders = await orderRepository.findAll(includeDeleted: true);
        final clients = await clientRepository.findAll(includeDeleted: true);
        final cars = await carRepository.findAll(includeDeleted: true);
        final clientById = <int, Client>{
          for (final client in clients) client.id: client,
        };
        final carById = <int, Car>{for (final car in cars) car.id: car};
        return [
          for (final order in orders)
            _OrderRow(
              order: order,
              clientName:
                  clientById[order.clientId]?.fullName.trim() ??
                  'Клиент не найден',
              carTitle: carById[order.carId]?.title ?? 'Автомобиль не найден',
            ),
        ];
      },
      idOf: (row) => row.order.id,
      titleOf: (row) => row.order.number,
      subtitleOf: (row) =>
          '${row.clientName} · ${row.carTitle} · ${row.order.status}',
      searchText: (row) =>
          '${row.order.number} ${row.clientName} ${row.carTitle} '
          '${row.order.description} ${row.order.status}',
      isDeleted: (row) => row.order.isDeleted,
      detailLocation: (row) => '/orders/${row.order.id}',
      editLocation: (row) => '/orders/${row.order.id}/edit',
      emptyMessage: 'Заказов пока нет',
      filterLabel: 'Статус',
      filterOptions: orderStatuses,
      filterOf: (row) => row.order.status,
      onSoftDelete: (id) =>
          context.read<ServiceOrderRepository>().softDelete(id),
      onHardDelete: (id) =>
          context.read<ServiceOrderRepository>().hardDelete(id),
      onRestore: (id) => context.read<ServiceOrderRepository>().restore(id),
    );
  }
}

class _OrderRow {
  const _OrderRow({
    required this.order,
    required this.clientName,
    required this.carTitle,
  });

  final ServiceOrder order;
  final String clientName;
  final String carTitle;
}
