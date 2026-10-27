String? required(String? value, [String message = 'Обязательное поле']) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

String? minLength(String? value, int length, [String? message]) {
  if (value == null || value.trim().isEmpty) return null;
  if (value.trim().length < length) {
    return message ?? 'Минимум $length символов';
  }
  return null;
}

String? maxLength(String? value, int length, [String? message]) {
  if (value == null || value.trim().isEmpty) return null;
  if (value.trim().length > length) {
    return message ?? 'Максимум $length символов';
  }
  return null;
}

String? email(String? value, [String message = 'Некорректный email']) {
  if (value == null || value.trim().isEmpty) return null;
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!regex.hasMatch(value.trim())) return message;
  return null;
}

String? phone(String? value, [String message = 'Некорректный телефон']) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 15) return message;
  return null;
}

String? vin(
  String? value, [
  String message = 'VIN: от 5 до 17 латинских букв и цифр',
]) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.trim().toUpperCase();
  if (!RegExp(r'^[A-HJ-NPR-Z0-9]{5,17}$').hasMatch(normalized)) {
    return message;
  }
  return null;
}

String? integer(String? value, [String message = 'Введите число']) {
  if (value == null || value.trim().isEmpty) return null;
  if (int.tryParse(value.trim()) == null) return message;
  return null;
}

String? minInt(String? value, int min, [String? message]) {
  if (value == null || value.trim().isEmpty) return null;
  final v = int.tryParse(value.trim());
  if (v == null) return 'Введите число';
  if (v < min) return message ?? 'Не меньше $min';
  return null;
}

String? maxInt(String? value, int max, [String? message]) {
  if (value == null || value.trim().isEmpty) return null;
  final v = int.tryParse(value.trim());
  if (v == null) return 'Введите число';
  if (v > max) return message ?? 'Не больше $max';
  return null;
}

String? positiveInt(
  String? value, [
  String message = 'Должно быть положительным',
]) {
  if (value == null || value.trim().isEmpty) return null;
  final v = int.tryParse(value.trim());
  if (v == null) return 'Введите число';
  if (v <= 0) return message;
  return null;
}

String? combine(String? value, List<String? Function(String?)> validators) {
  for (final v in validators) {
    final res = v(value);
    if (res != null) return res;
  }
  return null;
}
