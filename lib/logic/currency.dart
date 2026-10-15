import 'numbers.dart';

const Map<String, String> currencyNames = {
  'RUB': 'Российский рубль',
  'USD': 'Доллар США',
  'EUR': 'Евро',
  'CNY': 'Китайский юань',
  'KZT': 'Казахстанский тенге',
  'GBP': 'Фунт стерлингов',
  'JPY': 'Японская йена',
};

const Map<String, double> ratesPerUsd = {
  'USD': 1.0,
  'RUB': 84,
  'EUR': 0.92,
  'CNY': 7.24,
  'KZT': 470.0,
  'GBP': 0.79,
  'JPY': 157.0,
};

OperationResult convertCurrency({String? amount, String? from, String? to}) {
  final value = parseNumber(amount);
  if (value == null) {
    return const OperationFailure('В адресе передана не сумма');
  }
  if (from == null || to == null || from.isEmpty || to.isEmpty) {
    return const OperationFailure('Не указана валюта');
  }

  final fromRate = ratesPerUsd[from.toUpperCase()];
  final toRate = ratesPerUsd[to.toUpperCase()];
  if (fromRate == null || toRate == null) {
    return const OperationFailure('Неизвестная валюта');
  }

  return OperationSuccess(value / fromRate * toRate);
}
