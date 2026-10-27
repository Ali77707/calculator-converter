import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/loyalty_card.dart';
import '../repositories/client_repository.dart';
import '../repositories/loyalty_card_repository.dart';
import '../widgets/crud_list_page.dart';

class LoyaltyCardListScreen extends StatelessWidget {
  const LoyaltyCardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudListPage<_CardRow>(
      title: 'Карты лояльности',
      addLocation: '/loyalty-cards/new',
      searchHint: 'Поиск по номеру карты или клиенту',
      load: () async {
        final cardRepository = context.read<LoyaltyCardRepository>();
        final clientRepository = context.read<ClientRepository>();
        final cards = await cardRepository.findAll(includeDeleted: true);
        final clients = await clientRepository.findAll(includeDeleted: true);
        final clientById = <int, Client>{
          for (final client in clients) client.id: client,
        };
        return [
          for (final card in cards)
            _CardRow(
              card: card,
              clientName:
                  clientById[card.clientId]?.fullName.trim() ??
                  'Клиент не найден',
            ),
        ];
      },
      idOf: (row) => row.card.id,
      titleOf: (row) => row.card.number,
      subtitleOf: (row) =>
          '${row.clientName} · скидка ${row.card.discountPercent}% · '
          '${row.card.active ? 'активна' : 'неактивна'}',
      searchText: (row) =>
          '${row.card.number} ${row.clientName} '
          '${row.card.discountPercent}',
      isDeleted: (row) => row.card.isDeleted,
      detailLocation: (row) => '/loyalty-cards/${row.card.id}',
      editLocation: (row) => '/loyalty-cards/${row.card.id}/edit',
      emptyMessage: 'Карт лояльности пока нет',
      filterLabel: 'Активность',
      filterOptions: const ['Активна', 'Неактивна'],
      filterOf: (row) => row.card.active ? 'Активна' : 'Неактивна',
      onSoftDelete: (id) =>
          context.read<LoyaltyCardRepository>().softDelete(id),
      onHardDelete: (id) =>
          context.read<LoyaltyCardRepository>().hardDelete(id),
      onRestore: (id) => context.read<LoyaltyCardRepository>().restore(id),
    );
  }
}

class _CardRow {
  const _CardRow({required this.card, required this.clientName});

  final LoyaltyCard card;
  final String clientName;
}
