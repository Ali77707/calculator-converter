import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/service_order.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import '../widgets/detail_fields.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/page_layout.dart';

class ServiceOrderDetailScreen extends StatefulWidget {
  const ServiceOrderDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ServiceOrderDetailScreen> createState() =>
      _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState extends State<ServiceOrderDetailScreen> {
  ServiceOrder? _order;
  Client? _client;
  Car? _car;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orderRepository = context.read<ServiceOrderRepository>();
      final clientRepository = context.read<ClientRepository>();
      final carRepository = context.read<CarRepository>();
      final order = await orderRepository.findById(widget.id);
      final client = order == null
          ? null
          : await clientRepository.findById(order.clientId);
      final car = order == null
          ? null
          : await carRepository.findById(order.carId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _client = client;
        _car = car;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _softDelete() async {
    final ok = await _confirm(
      'Удалить заказ?',
      'Заказ будет скрыт, его можно восстановить.',
    );
    if (!ok || !mounted) return;
    await context.read<ServiceOrderRepository>().softDelete(widget.id);
    await _load();
  }

  Future<void> _hardDelete() async {
    final ok = await _confirm(
      'Удалить навсегда?',
      'Заказ будет удалён без возможности восстановления.',
    );
    if (!ok || !mounted) return;
    await context.read<ServiceOrderRepository>().hardDelete(widget.id);
    if (mounted) context.go('/orders');
  }

  Future<void> _restore() async {
    await context.read<ServiceOrderRepository>().restore(widget.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Заказ не найден'),
      );
    }

    return PageLayout(
      title: order.number,
      maxWidth: 760,
      actions: [
        if (!order.isDeleted)
          IconButton(
            tooltip: 'Изменить',
            onPressed: () => context.go('/orders/${order.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'soft':
                await _softDelete();
                break;
              case 'hard':
                await _hardDelete();
                break;
              case 'restore':
                await _restore();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!order.isDeleted)
              const PopupMenuItem(value: 'soft', child: Text('Удалить')),
            if (order.isDeleted)
              const PopupMenuItem(
                value: 'restore',
                child: Text('Восстановить'),
              ),
            const PopupMenuItem(value: 'hard', child: Text('Удалить навсегда')),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.isDeleted && order.deletedAt != null) ...[
            DeletedBanner(date: order.deletedAt!),
            const SizedBox(height: 16),
          ],
          DetailSection(
            title: 'Информация о заказе',
            children: [
              DetailRow(label: 'Номер', value: order.number),
              DetailRow(label: 'Статус', value: order.status),
              DetailRow(
                label: 'Клиент',
                value: _client?.fullName.trim() ?? 'Клиент не найден',
              ),
              DetailRow(
                label: 'Автомобиль',
                value: _car == null
                    ? 'Автомобиль не найден'
                    : '${_car!.title} · ${_car!.vin}',
              ),
              DetailRow(label: 'Описание', value: order.description),
              DetailRow(label: 'Стоимость', value: '${order.price} ₽'),
              DetailRow(label: 'Создан', value: ruDate(order.createdAt)),
              if (order.deletedAt != null)
                DetailRow(
                  label: 'Дата удаления',
                  value: ruDate(order.deletedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
