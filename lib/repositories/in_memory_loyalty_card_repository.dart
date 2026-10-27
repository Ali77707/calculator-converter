import 'package:shared_preferences/shared_preferences.dart';

import '../models/loyalty_card.dart';
import 'json_store.dart';
import 'loyalty_card_repository.dart';
import 'seed_data.dart';

class InMemoryLoyaltyCardRepository implements LoyaltyCardRepository {
  InMemoryLoyaltyCardRepository({
    List<LoyaltyCard>? seed,
    SharedPreferences? prefs,
  }) : _store = JsonStore(prefs, 'loyalty_cards_v2'),
       _cards = <LoyaltyCard>[] {
    final initial = seed ?? seedLoyaltyCards();
    _cards = prefs == null
        ? List.of(initial)
        : _store.read(LoyaltyCard.fromJson, initial);
    _nextId = _cards.fold<int>(1, (max, c) => c.id >= max ? c.id + 1 : max);
  }

  final JsonStore _store;
  late List<LoyaltyCard> _cards;
  late int _nextId;

  @override
  Future<List<LoyaltyCard>> findAll({bool includeDeleted = false}) async {
    return _cards
        .where((c) => includeDeleted || !c.isDeleted)
        .toList(growable: false);
  }

  @override
  Future<LoyaltyCard?> findById(int id) async {
    for (final card in _cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  @override
  Future<LoyaltyCard?> findByClient(int clientId) async {
    for (final card in _cards) {
      if (card.clientId == clientId && !card.isDeleted) return card;
    }
    return null;
  }

  @override
  Future<LoyaltyCard> create(LoyaltyCard card) async {
    final created = LoyaltyCard(
      id: _nextId++,
      clientId: card.clientId,
      number: card.number,
      issuedAt: card.issuedAt,
      discountPercent: card.discountPercent,
      active: card.active,
    );
    _cards.add(created);
    await _persist();
    return created;
  }

  @override
  Future<LoyaltyCard> update(LoyaltyCard card) async {
    final i = _cards.indexWhere((c) => c.id == card.id);
    if (i == -1) throw StateError('Карта ${card.id} не найдена');
    _cards[i] = card;
    await _persist();
    return card;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _cards.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Карта $id не найдена');
    _cards[i] = _cards[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _cards.removeWhere((c) => c.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _cards.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Карта $id не найдена');
    _cards[i] = _cards[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  Future<void> _persist() => _store.write(_cards, (c) => c.toJson());
}
