import 'numbers.dart';

const List<String> supportedOperations = ['+', '-', '*', '/'];

String? normalizeOperation(String? raw) {
  if (raw == null) return null;
  if (raw == ' ' || raw == '+') return '+';
  final trimmed = raw.trim();
  return trimmed.isEmpty ? '+' : trimmed;
}

OperationResult calculate({String? a, String? op, String? b}) {
  final first = parseNumber(a);
  final second = parseNumber(b);

  if (first == null || second == null) {
    return const OperationFailure('В адресе переданы не числа');
  }

  return switch (normalizeOperation(op)) {
    '+' => OperationSuccess(first + second),
    '-' => OperationSuccess(first - second),
    '*' => OperationSuccess(first * second),
    '/' =>
      second == 0
          ? const OperationFailure('Деление на ноль невозможно')
          : OperationSuccess(first / second),
    _ => const OperationFailure('Неизвестная операция'),
  };
}
