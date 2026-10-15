library;

sealed class OperationResult {
  const OperationResult();
}

class OperationSuccess extends OperationResult {
  final double value;

  const OperationSuccess(this.value);
}

class OperationFailure extends OperationResult {
  final String message;

  const OperationFailure(this.message);
}

double? parseNumber(String? raw) {
  if (raw == null) return null;
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String formatNumber(double value, {int fractionDigits = 6}) {
  if (value.isNaN) return 'не число';

  final rounded = double.parse(value.toStringAsFixed(fractionDigits));
  if (rounded == rounded.truncateToDouble() && rounded.abs() < 1e15) {
    return rounded.toInt().toString();
  }

  var text = rounded.toStringAsFixed(fractionDigits);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return text;
}
