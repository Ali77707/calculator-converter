import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/client.dart';
import '../models/loyalty_card.dart';
import '../repositories/client_repository.dart';
import '../repositories/loyalty_card_repository.dart';
import '../widgets/detail_fields.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/page_layout.dart';

class LoyaltyCardDetailScreen extends StatefulWidget {
  const LoyaltyCardDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<LoyaltyCardDetailScreen> createState() =>
      _LoyaltyCardDetailScreenState();
}

class _LoyaltyCardDetailScreenState extends State<LoyaltyCardDetailScreen> {
  LoyaltyCard? _card;
  Client? _client;
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
      final cardRepository = context.read<LoyaltyCardRepository>();
      final clientRepository = context.read<ClientRepository>();
      final card = await cardRepository.findById(widget.id);
      final client = card == null
          ? null
          : await clientRepository.findById(card.clientId);
      if (!mounted) return;
      setState(() {
        _card = card;
        _client = client;
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
      'Удалить карту?',
      'Карта будет скрыта, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    await context.read<LoyaltyCardRepository>().softDelete(widget.id);
    await _load();
  }

  Future<void> _hardDelete() async {
    final ok = await _confirm(
      'Удалить навсегда?',
      'Карта будет удалена без возможности восстановления.',
    );
    if (!ok || !mounted) return;
    await context.read<LoyaltyCardRepository>().hardDelete(widget.id);
    if (mounted) context.go('/loyalty-cards');
  }

  Future<void> _restore() async {
    await context.read<LoyaltyCardRepository>().restore(widget.id);
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
    final card = _card;
    if (card == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Карта не найдена'),
      );
    }

    return PageLayout(
      title: card.number,
      maxWidth: 760,
      actions: [
        if (!card.isDeleted)
          IconButton(
            tooltip: 'Изменить',
            onPressed: () => context.go('/loyalty-cards/${card.id}/edit'),
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
            if (!card.isDeleted)
              const PopupMenuItem(value: 'soft', child: Text('Удалить')),
            if (card.isDeleted)
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
          if (card.isDeleted && card.deletedAt != null) ...[
            DeletedBanner(date: card.deletedAt!),
            const SizedBox(height: 16),
          ],
          DetailSection(
            title: 'Информация о карте',
            children: [
              DetailRow(label: 'Номер', value: card.number),
              DetailRow(
                label: 'Клиент',
                value: _client?.fullName.trim() ?? 'Клиент не найден',
              ),
              DetailRow(label: 'Скидка', value: '${card.discountPercent}%'),
              DetailRow(label: 'Дата выдачи', value: ruDate(card.issuedAt)),
              DetailRow(
                label: 'Статус',
                value: card.active ? 'Активна' : 'Неактивна',
              ),
              if (card.deletedAt != null)
                DetailRow(
                  label: 'Дата удаления',
                  value: ruDate(card.deletedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
