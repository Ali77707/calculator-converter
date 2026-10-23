import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'client_repository.dart';
import 'seed_data.dart';

class InMemoryClientRepository implements ClientRepository {
  InMemoryClientRepository({List<Client>? seed})
    : _clients = List.of(seed ?? seedClients()) {
    _nextId = _clients.fold<int>(1, (max, c) => c.id >= max ? c.id + 1 : max);
  }

  final List<Client> _clients;
  late int _nextId;

  static const Duration _latency = Duration(milliseconds: 250);

  @override
  Future<PageResult<Client>> find(ClientQuery q) async {
    await Future<void>.delayed(_latency);

    var rows = _clients.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (c) =>
                c.lastName.toLowerCase().contains(needle) ||
                c.city.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.city != null) {
      rows = rows.where((c) => c.city == q.city).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((c) => c.registeredAt.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((c) => c.registeredAt.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final int result = switch (q.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'phone' => a.phone.compareTo(b.phone),
        'registeredAt' => a.registeredAt.compareTo(b.registeredAt),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      if (result != 0) return q.sortAscending ? result : -result;
      return a.id.compareTo(b.id);
    });

    final total = rows.length;
    final totalPages = total == 0 ? 1 : (total / q.size).ceil();
    final page = q.page < 1 ? 1 : (q.page > totalPages ? totalPages : q.page);

    final from = (page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Client>[] : rows.sublist(from, to);

    return PageResult(items: items, page: page, size: q.size, total: total);
  }

  @override
  Future<Client?> findById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (final client in _clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<Client> create(Client client) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final created = Client(
      id: _nextId++,
      lastName: client.lastName,
      firstName: client.firstName,
      middleName: client.middleName,
      city: client.city,
      phone: client.phone,
      email: client.email,
      registeredAt: client.registeredAt,
    );
    _clients.add(created);
    return created;
  }

  @override
  Future<Client> update(Client client) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i == -1) throw StateError('Клиент ${client.id} не найден');
    _clients[i] = client;
    return client;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Клиент $id не найден');
    _clients[i] = _clients[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _clients.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Клиент $id не найден');
    _clients[i] = _clients[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    var count = 0;
    for (final id in ids) {
      final i = _clients.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _clients[i] = _clients[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
