import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/client.dart';
import '../models/service_order.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import '../utils/validators.dart' as v;
import '../widgets/form_page_layout.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/unsaved_changes_guard.dart';

class ServiceOrderFormScreen extends StatefulWidget {
  const ServiceOrderFormScreen({super.key, this.id});

  final int? id;

  @override
  State<ServiceOrderFormScreen> createState() => _ServiceOrderFormScreenState();
}

class _ServiceOrderFormScreenState extends State<ServiceOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  ServiceOrder? _order;
  List<ServiceOrder> _allOrders = const [];
  List<Client> _clients = const [];
  List<Car> _cars = const [];
  int? _clientId;
  int? _carId;
  String _status = orderStatuses.first;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  bool get _isEdit => widget.id != null;

  List<Car> get _availableCars {
    if (_clientId == null) return const [];
    return _cars
        .where((car) => car.ownerIds.contains(_clientId))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orderRepository = context.read<ServiceOrderRepository>();
      final clientRepository = context.read<ClientRepository>();
      final carRepository = context.read<CarRepository>();
      final orders = await orderRepository.findAll(includeDeleted: true);
      final clients = await clientRepository.findAll(includeDeleted: true);
      final cars = await carRepository.findAll(includeDeleted: true);
      final order = _isEdit ? await orderRepository.findById(widget.id!) : null;
      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _clients = clients;
        _cars = cars;
        _order = order;
        _loading = false;
        if (order != null) {
          _numberController.text = order.number;
          _descriptionController.text = order.description;
          _priceController.text = '${order.price}';
          _clientId = order.clientId;
          _carId = order.carId;
          _status = order.status;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    final base = v.combine(value, [
      (value) => v.required(value, 'Введите номер заказа'),
      (value) => v.minLength(value, 3),
      (value) => v.maxLength(value, 30),
    ]);
    if (base != null) return base;
    final normalized = value!.trim().toLowerCase();
    final duplicate = _allOrders.any(
      (order) =>
          order.id != _order?.id &&
          order.number.trim().toLowerCase() == normalized,
    );
    return duplicate ? 'Заказ с таким номером уже существует' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final order = ServiceOrder(
      id: _order?.id ?? 0,
      number: _numberController.text.trim().toUpperCase(),
      carId: _carId!,
      clientId: _clientId!,
      description: _descriptionController.text.trim(),
      status: _status,
      price: int.parse(_priceController.text.trim()),
      createdAt: _order?.createdAt ?? DateTime.now(),
    );
    try {
      if (_isEdit) {
        await context.read<ServiceOrderRepository>().update(order);
      } else {
        await context.read<ServiceOrderRepository>().create(order);
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.go('/orders');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $error')));
    }
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
    if (_isEdit && _order == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Заказ не найден'),
      );
    }

    final availableCars = _availableCars;
    final hasSelectedCar = availableCars.any((car) => car.id == _carId);

    return UnsavedChangesGuard(
      hasChanges: _dirty,
      child: FormPageLayout(
        title: _isEdit ? 'Редактирование заказа' : 'Новый заказ',
        formKey: _formKey,
        saving: _saving,
        onSave: _save,
        hasUnsavedChanges: _dirty,
        children: [
          FormSection(
            title: 'Заказ',
            children: [
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Номер заказа',
                  hintText: 'Order-2026-0001',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _dirty = true),
                validator: _validateNumber,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _clients.any((c) => c.id == _clientId)
                    ? _clientId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Клиент',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final client in _clients)
                    DropdownMenuItem(
                      value: client.id,
                      child: Text(
                        client.isDeleted
                            ? '${client.fullName.trim()} (удалён)'
                            : client.fullName.trim(),
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _clientId = value;
                    if (!_availableCars.any((car) => car.id == _carId)) {
                      _carId = null;
                    }
                    _dirty = true;
                  });
                },
                validator: (value) => value == null ? 'Выберите клиента' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: hasSelectedCar ? _carId : null,
                decoration: InputDecoration(
                  labelText: 'Автомобиль',
                  border: const OutlineInputBorder(),
                  helperText: _clientId == null
                      ? 'Сначала выберите клиента'
                      : availableCars.isEmpty
                      ? 'У клиента пока нет автомобилей'
                      : null,
                ),
                items: [
                  for (final car in availableCars)
                    DropdownMenuItem(
                      value: car.id,
                      child: Text(
                        '${car.title} · ${car.vin}'
                        '${car.isDeleted ? ' (удалён)' : ''}',
                      ),
                    ),
                ],
                onChanged: _clientId == null || availableCars.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _carId = value;
                          _dirty = true;
                        });
                      },
                validator: (value) =>
                    value == null ? 'Выберите автомобиль клиента' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: orderStatuses.contains(_status)
                    ? _status
                    : orderStatuses.first,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final status in orderStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value ?? orderStatuses.first;
                    _dirty = true;
                  });
                },
              ),
            ],
          ),
          FormSection(
            title: 'Работы',
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание работ',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Опишите работы'),
                  (value) => v.minLength(value, 3),
                  (value) => v.maxLength(value, 500),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Стоимость, ₽',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите стоимость'),
                  (value) => v.integer(value),
                  (value) =>
                      v.positiveInt(value, 'Стоимость должна быть больше нуля'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
