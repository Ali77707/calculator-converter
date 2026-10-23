import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/dictionaries.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../widgets/detail_fields.dart';
import '../widgets/list_state_view.dart';
import '../widgets/page_layout.dart';

import 'not_found_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {

  late Future<({Client? client, List<Car> cars})> _loading;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<({Client? client, List<Car> cars})> _load() async {

    final clients = context.read<ClientRepository>();
    final carsRepository = context.read<CarRepository>();
    final client = await clients.findById(widget.id);
    if (client == null) return (client: null, cars: <Car>[]);
    final cars = await carsRepository.findByOwner(client.id);
    return (client: client, cars: cars);
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

  Future<void> _confirmSoftDelete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text(
          '«${client.fullName}» будет помечен как удалённый и уйдёт из '
          'списка. Запись можно вернуть, включив показ удалённых.',
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
      await context.read<ClientRepository>().softDelete(client.id);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmHardDelete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Стереть запись насовсем?'),
        content: Text(
          '«${client.fullName}» будет удалено без возможности '
          'восстановления. Отменить действие после подтверждения нельзя.',
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
      await context.read<ClientRepository>().hardDelete(client.id);
      if (!mounted) return;
      context.go('/clients');
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _restore(Client client) async {
    try {
      await context.read<ClientRepository>().restore(client.id);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Client? client, List<Car> cars})>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PageLayout(
            title: 'Клиент',
            maxWidth: 720,
            child: LoadingView(label: 'Загрузка карточки…'),
          );
        }
        if (snapshot.hasError) {
          return PageLayout(
            title: 'Клиент',
            maxWidth: 720,
            child: ErrorView(message: '${snapshot.error}', onRetry: _reload),
          );
        }
        final client = snapshot.data?.client;
        if (client == null) {
          return NotFoundScreen(location: '/clients/${widget.id}');
        }
        return _ClientDetailView(
          client: client,
          cars: snapshot.data!.cars,
          onSoftDelete: () => _confirmSoftDelete(client),
          onHardDelete: () => _confirmHardDelete(client),
          onRestore: () => _restore(client),
        );
      },
    );
  }
}

class _ClientDetailView extends StatelessWidget {
  const _ClientDetailView({
    required this.client,
    required this.cars,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final Client client;
  final List<Car> cars;
  final VoidCallback onSoftDelete;
  final VoidCallback onHardDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageLayout(
      title: client.fullName,
      maxWidth: 720,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/clients');
          }
        },
      ),
      actions: [
        if (client.isDeleted)
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
          if (client.isDeleted) ...[
            DeletedBanner(date: client.deletedAt!),
            const SizedBox(height: 16),
          ],
          DetailSection(
            title: 'Клиент',
            children: [
              DetailRow(label: 'Фамилия', value: client.lastName),
              DetailRow(label: 'Имя', value: client.firstName),
              DetailRow(label: 'Отчество', value: client.middleName),
              DetailRow(label: 'Город', value: client.city),
              DetailRow(label: 'Телефон', value: client.phone),
              DetailRow(label: 'E-mail', value: client.email),
              DetailRow(
                label: 'В автосервисе с',
                value: ruDate(client.registeredAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Автомобили',
            children: cars.isEmpty
                ? [
                    Text(
                      'У клиента нет автомобилей.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ]
                : [
                    for (final car in cars)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(car.title),
                        subtitle: Text(
                          '${car.year} · ${makeName(car.makeId)} · '
                          '${car.mileage} км',
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
