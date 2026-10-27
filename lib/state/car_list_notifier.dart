import 'package:flutter/foundation.dart';

import '../models/car.dart';
import '../models/car_query.dart';
import '../models/page_result.dart';
import '../repositories/car_repository.dart';
import 'load_status.dart';

class CarListNotifier extends ChangeNotifier {
  CarListNotifier(this._repository);

  final CarRepository _repository;

  CarQuery _query = const CarQuery();
  PageResult<Car> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  CarQuery get query => _query;

  PageResult<Car> get result => _result;

  LoadStatus get status => _status;

  String? get error => _error;

  Set<int> get selected => Set.unmodifiable(_selected);

  bool get hasSelection => _selected.isNotEmpty;

  int get selectedCount => _selected.length;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    try {
      _result = await _repository.find(_query);

      if (_result.page != _query.page) {
        _query = _query.copyWith(page: _result.page);
      }
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(CarQuery next) async {
    _query = next;

    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void selectAll(Iterable<int> ids, bool selected) {
    if (selected) {
      _selected.addAll(ids);
    } else {
      _selected.removeAll(ids);
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}
