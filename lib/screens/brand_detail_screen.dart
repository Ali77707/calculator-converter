import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/brand.dart';
import '../models/car.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_repository.dart';
import '../widgets/detail_fields.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/page_layout.dart';

class BrandDetailScreen extends StatefulWidget {
  const BrandDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  Brand? _brand;
  List<Car> _cars = const [];
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
      final brandRepository = context.read<BrandRepository>();
      final carRepository = context.read<CarRepository>();
      final brand = await brandRepository.findById(widget.id);
      final cars = await carRepository.findAll(includeDeleted: true);
      if (!mounted) return;
      setState(() {
        _brand = brand;
        _cars = [
          for (final car in cars)
            if (car.makeId == widget.id) car,
        ];
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
    if (_cars.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Нельзя удалить марку: используется в ${_cars.length} автомобилях',
          ),
        ),
      );
      return;
    }
    final ok = await _confirm(
      'Удалить марку?',
      'Марка будет скрыта, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    await context.read<BrandRepository>().softDelete(widget.id);
    await _load();
  }

  Future<void> _hardDelete() async {
    if (_cars.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Нельзя удалить марку: используется в ${_cars.length} автомобилях',
          ),
        ),
      );
      return;
    }
    final ok = await _confirm(
      'Удалить навсегда?',
      'Марка будет удалена без возможности восстановления.',
    );
    if (!ok || !mounted) return;
    await context.read<BrandRepository>().hardDelete(widget.id);
    if (mounted) context.go('/brands');
  }

  Future<void> _restore() async {
    await context.read<BrandRepository>().restore(widget.id);
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
    final brand = _brand;
    if (brand == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Марка не найдена'),
      );
    }

    return PageLayout(
      title: brand.name,
      maxWidth: 760,
      actions: [
        if (!brand.isDeleted)
          IconButton(
            tooltip: 'Изменить',
            onPressed: () => context.go('/brands/${brand.id}/edit'),
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
            if (!brand.isDeleted)
              const PopupMenuItem(value: 'soft', child: Text('Удалить')),
            if (brand.isDeleted)
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
          if (brand.isDeleted && brand.deletedAt != null) ...[
            DeletedBanner(date: brand.deletedAt!),
            const SizedBox(height: 16),
          ],
          DetailSection(
            title: 'Информация о марке',
            children: [
              DetailRow(label: 'Название', value: brand.name),
              DetailRow(label: 'Страна', value: brand.country),
              DetailRow(label: 'Автомобилей в базе', value: '${_cars.length}'),
              if (brand.deletedAt != null)
                DetailRow(
                  label: 'Дата удаления',
                  value: ruDate(brand.deletedAt!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Автомобили марки',
            children: _cars.isEmpty
                ? [
                    Text(
                      'У марки пока нет автомобилей.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ]
                : [
                    for (final car in _cars)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${car.title}${car.isDeleted ? ' (удалён)' : ''}',
                        ),
                        subtitle: Text(
                          '${car.year} · ${car.vin} · ${car.mileage} км',
                        ),
                        onTap: () => context.go('/cars/${car.id}'),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
