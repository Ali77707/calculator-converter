import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/dictionaries.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../utils/validators.dart' as v;
import '../widgets/form_page_layout.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/unsaved_changes_guard.dart';

class CarFormScreen extends StatefulWidget {
  const CarFormScreen({super.key, this.id});

  final int? id;

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _vinController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _priceController = TextEditingController();

  Car? _car;
  List<Brand> _brands = const [];
  List<Client> _clients = const [];
  List<Car> _allCars = const [];
  int? _makeId;
  int? _bodyTypeId;
  String? _fuel;
  Set<int> _ownerIds = {};
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final carRepository = context.read<CarRepository>();
      final brandRepository = context.read<BrandRepository>();
      final clientRepository = context.read<ClientRepository>();
      final cars = await carRepository.findAll(includeDeleted: true);
      final brands = await brandRepository.findAll(includeDeleted: true);
      final clients = await clientRepository.findAll(includeDeleted: true);
      final car = _isEdit ? await carRepository.findById(widget.id!) : null;
      if (!mounted) return;
      setState(() {
        _allCars = cars;
        _brands = brands;
        _clients = clients;
        _car = car;
        _loading = false;
        if (car != null) {
          _titleController.text = car.title;
          _vinController.text = car.vin;
          _yearController.text = '${car.year}';
          _mileageController.text = '${car.mileage}';
          _priceController.text = '${car.price}';
          _makeId = car.makeId;
          _bodyTypeId = car.bodyTypeId;
          _fuel = car.fuel;
          _ownerIds = car.ownerIds.toSet();
        } else {
          _bodyTypeId = bodyTypes.first.id;
          _fuel = fuelTypes.first;
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
    _titleController.dispose();
    _vinController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _validateVin(String? value) {
    final base = v.combine(value, [
      (value) => v.required(value, 'Введите VIN'),
      (value) => v.vin(value),
    ]);
    if (base != null) return base;
    final normalized = value!.trim().toLowerCase();
    final duplicate = _allCars.any(
      (car) => car.id != _car?.id && car.vin.trim().toLowerCase() == normalized,
    );
    return duplicate ? 'Такой VIN уже есть в базе' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final car = Car(
      id: _car?.id ?? 0,
      title: _titleController.text.trim(),
      vin: _vinController.text.trim().toUpperCase(),
      year: int.parse(_yearController.text.trim()),
      mileage: int.parse(_mileageController.text.trim()),
      makeId: _makeId!,
      bodyTypeId: _bodyTypeId!,
      fuel: _fuel!,
      price: int.parse(_priceController.text.trim()),
      ownerIds: _ownerIds.toList(),
    );
    try {
      if (_isEdit) {
        await context.read<CarRepository>().update(car);
      } else {
        await context.read<CarRepository>().create(car);
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.go('/cars');
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
    if (_isEdit && _car == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Автомобиль не найден'),
      );
    }

    return UnsavedChangesGuard(
      hasChanges: _dirty,
      child: FormPageLayout(
        title: _isEdit ? 'Редактирование автомобиля' : 'Новый автомобиль',
        formKey: _formKey,
        saving: _saving,
        onSave: _save,
        hasUnsavedChanges: _dirty,
        children: [
          FormSection(
            title: 'Основные данные',
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например, Toyota Camry 2.5',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите название'),
                  (value) => v.minLength(value, 3),
                  (value) => v.maxLength(value, 100),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(
                  labelText: 'VIN',
                  hintText: '17 символов',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _dirty = true),
                validator: _validateVin,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Год выпуска',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _dirty = true),
                      validator: (value) => v.combine(value, [
                        (value) => v.required(value, 'Введите год'),
                        (value) => v.integer(value),
                        (value) => v.minInt(value, 1900, 'Год не раньше 1900'),
                        (value) => v.maxInt(value, 2100, 'Год не позже 2100'),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mileageController,
                      decoration: const InputDecoration(
                        labelText: 'Пробег, км',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _dirty = true),
                      validator: (value) => v.combine(value, [
                        (value) => v.required(value, 'Введите пробег'),
                        (value) => v.integer(value),
                        (value) => v.minInt(
                          value,
                          0,
                          'Пробег не может быть отрицательным',
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена, ₽',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите цену'),
                  (value) => v.integer(value),
                  (value) =>
                      v.positiveInt(value, 'Цена должна быть больше нуля'),
                ]),
              ),
            ],
          ),
          FormSection(
            title: 'Характеристики',
            children: [
              DropdownButtonFormField<int>(
                initialValue: _makeId,
                decoration: const InputDecoration(
                  labelText: 'Марка',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final brand in _brands)
                    DropdownMenuItem(
                      value: brand.id,
                      child: Text(
                        brand.isDeleted
                            ? '${brand.name} (удалена)'
                            : brand.name,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _makeId = value;
                    _dirty = true;
                  });
                },
                validator: (value) => value == null ? 'Выберите марку' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _bodyTypeId,
                decoration: const InputDecoration(
                  labelText: 'Тип кузова',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in bodyTypes)
                    DropdownMenuItem(value: type.id, child: Text(type.name)),
                ],
                onChanged: (value) {
                  setState(() {
                    _bodyTypeId = value;
                    _dirty = true;
                  });
                },
                validator: (value) =>
                    value == null ? 'Выберите тип кузова' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _fuel,
                decoration: const InputDecoration(
                  labelText: 'Топливо',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final fuel in fuelTypes)
                    DropdownMenuItem(value: fuel, child: Text(fuel)),
                ],
                onChanged: (value) {
                  setState(() {
                    _fuel = value;
                    _dirty = true;
                  });
                },
                validator: (value) =>
                    value == null ? 'Выберите тип топлива' : null,
              ),
            ],
          ),
          FormSection(
            title: 'Владельцы',
            children: [
              FormField<Set<int>>(
                initialValue: _ownerIds,
                validator: (value) => value == null || value.isEmpty
                    ? 'Выберите хотя бы одного владельца'
                    : null,
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final client in _clients)
                            FilterChip(
                              label: Text(
                                client.isDeleted
                                    ? '${client.fullName.trim()} (удалён)'
                                    : client.fullName.trim(),
                              ),
                              selected: _ownerIds.contains(client.id),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _ownerIds.add(client.id);
                                  } else {
                                    _ownerIds.remove(client.id);
                                  }
                                  _dirty = true;
                                });
                                field.didChange(_ownerIds);
                              },
                            ),
                        ],
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 8),
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
