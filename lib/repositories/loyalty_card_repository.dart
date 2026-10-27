import '../models/loyalty_card.dart';

abstract interface class LoyaltyCardRepository {
  Future<List<LoyaltyCard>> findAll({bool includeDeleted = false});
  Future<LoyaltyCard?> findById(int id);
  Future<LoyaltyCard?> findByClient(int clientId);
  Future<LoyaltyCard> create(LoyaltyCard card);
  Future<LoyaltyCard> update(LoyaltyCard card);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
}
