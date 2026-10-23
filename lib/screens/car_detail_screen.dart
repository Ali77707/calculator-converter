import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/client.dart';
import '../models/dictionaries.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../widgets/detail_fields.dart';
import '../widgets/list_state_view.dart';
import '../widgets/page_layout.dart';

import 'not_found_screen.dart';

class CarDetailScreen extends StatefulWidget {
  const CarDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {

  late Future<({Car? car, List<Client> owners})> _loading;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<({Car? car, List<Client> owners})> _load() async {

    final cars = context.read<CarRepository>();
    final clients = context.read<ClientRepository>();
    final car = await cars.findById(widget.id);
    if (car == null) return (car: null, owners: <Client>[]);
    final owners = <Client>[];
    for (final ownerId in car.ownerIds) {
      final owner = await clients.findById(ownerId);
      if (owner != null) owners.add(owner);
    }
    return (car: car, owners: owners);
  }

  void _reload() {
    setState(() => _loading = _load());
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не выполнить действие: $error')),
    );
  }

  Future<void> _confirmSoftDelete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text(
          '«${car.title}» будет помечен как удалённый и уйдёт из списка. '
          'Запись можно вернуть, включив показ удалённых.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CarRepository>().softDelete(car.id);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmHardDelete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Стереть запись насовсем?'),
        content: Text(
          '«${car.title}» будет удалено без возможности восстановления. '
          'Отменить действие после подтверждения нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Стереть'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CarRepository>().hardDelete(car.id);
      if (!mounted) return;
      context.go('/cars');
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _restore(Car car) async {
    try {
      await context.read<CarRepository>().restore(car.id);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Car? car, List<Client> owners})>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PageLayout(
            title: 'Автомобиль',
            maxWidth: 720,
            child: LoadingView(label: 'Загрузка карточки…'),
          );
        }
        if (snapshot.hasError) {
          return PageLayout(
            title: 'Автомобиль',
            maxWidth: 720,
            child: ErrorView(message: '${snapshot.error}', onRetry: _reload),
          );
        }
        final car = snapshot.data?.car;
        if (car == null) {
          return NotFoundScreen(location: '/cars/${widget.id}');
        }
        return _CarDetailView(
          car: car,
          owners: snapshot.data!.owners,
          onSoftDelete: () => _confirmSoftDelete(car),
          onHardDelete: () => _confirmHardDelete(car),
          onRestore: () => _restore(car),
        );
      },
    );
  }
}

class _CarDetailView extends StatelessWidget {
  const _CarDetailView({
    required this.car,
    required this.owners,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final Car car;
  final List<Client> owners;
  final VoidCallback onSoftDelete;
  final VoidCallback onHardDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageLayout(
      title: car.title,
      maxWidth: 720,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/cars');
          }
        },
      ),
      actions: [
        if (car.isDeleted)
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: onRestore,
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onSoftDelete,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: onHardDelete,
          ),
        ],
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (car.isDeleted) ...[
            DeletedBanner(date: car.deletedAt!),
            const SizedBox(height: 16),
          ],
          DetailSection(
            title: 'Автомобиль',
            children: [
              DetailRow(label: 'Название', value: car.title),
              DetailRow(label: 'VIN', value: car.vin),
              DetailRow(label: 'Марка', value: makeName(car.makeId)),
              DetailRow(label: 'Тип кузова', value: bodyTypeName(car.bodyTypeId)),
              DetailRow(label: 'Топливо', value: car.fuel),
              DetailRow(label: 'Год выпуска', value: '${car.year}'),
              DetailRow(label: 'Пробег', value: '${car.mileage} км'),
              DetailRow(label: 'Стоимость', value: '${car.price} ₽'),
            ],
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Владельцы',
            children: owners.isEmpty
                ? [
                    Text(
                      'Владельцы не указаны.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ]
                : [
                    for (final owner in owners)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(owner.fullName),
                        subtitle: Text('${owner.city} · ${owner.phone}'),
                        onTap: () => context.go('/clients/${owner.id}'),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
