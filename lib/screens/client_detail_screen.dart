import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/dictionaries.dart';
import '../models/loyalty_card.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/loyalty_card_repository.dart';
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
  late Future<
    ({
      Client? client,
      List<Car> cars,
      Map<int, String> brandNames,
      LoyaltyCard? card,
    })
  >
  _loading;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<
    ({
      Client? client,
      List<Car> cars,
      Map<int, String> brandNames,
      LoyaltyCard? card,
    })
  >
  _load() async {
    final clients = context.read<ClientRepository>();
    final carsRepository = context.read<CarRepository>();
    final brandsRepository = context.read<BrandRepository>();
    final cardsRepository = context.read<LoyaltyCardRepository>();
    final client = await clients.findById(widget.id);
    if (client == null) {
      return (
        client: null,
        cars: <Car>[],
        brandNames: <int, String>{},
        card: null,
      );
    }
    final cars = await carsRepository.findByOwner(client.id);
    final brands = await brandsRepository.findAll(includeDeleted: true);
    final cards = await cardsRepository.findAll(includeDeleted: true);
    LoyaltyCard? card;
    for (final item in cards) {
      if (item.clientId == client.id) {
        card = item;
        break;
      }
    }
    return (
      client: client,
      cars: cars,
      brandNames: {
        for (final brand in brands)
          brand.id: brand.isDeleted ? '${brand.name} (удалена)' : brand.name,
      },
      card: card,
    );
  }

  void _reload() {
    setState(() => _loading = _load());
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось выполнить действие: $error')),
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
    return FutureBuilder<
      ({
        Client? client,
        List<Car> cars,
        Map<int, String> brandNames,
        LoyaltyCard? card,
      })
    >(
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
          brandNames: snapshot.data!.brandNames,
          card: snapshot.data!.card,
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
    required this.brandNames,
    required this.card,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final Client client;
  final List<Car> cars;
  final Map<int, String> brandNames;
  final LoyaltyCard? card;

  String _brandName(int id) => brandNames[id] ?? makeName(id);
  final VoidCallback onSoftDelete;
  final VoidCallback onHardDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageLayout(
      title: client.fullName,
      maxWidth: 720,
      actions: [
        if (client.isDeleted)
          IconButton(icon: const Icon(Icons.restore), onPressed: onRestore)
        else ...[
          IconButton(
            tooltip: 'Изменить',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/clients/${client.id}/edit'),
          ),
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
            title: 'Карта лояльности',
            children: card == null
                ? [
                    Text(
                      'У клиента нет карты лояльности.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ]
                : [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Карта ${card!.number}'
                        '${card!.isDeleted ? ' (удалена)' : ''}',
                      ),
                      subtitle: Text(
                        'Скидка ${card!.discountPercent}% · '
                        '${card!.active ? 'активна' : 'неактивна'} · '
                        'выдана ${ruDate(card!.issuedAt)}',
                      ),
                      onTap: () => context.go('/loyalty-cards/${card!.id}'),
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
                          '${car.year} · ${_brandName(car.makeId)} · '
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
