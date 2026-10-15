import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/calculator.dart';
import '../logic/numbers.dart';
import '../widgets/page_layout.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    this.initialA,
    this.initialOp,
    this.initialB,
  });

  final String? initialA;
  final String? initialOp;
  final String? initialB;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _aController;
  late final TextEditingController _bController;
  late String _operation;

  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    _aController = TextEditingController(text: widget.initialA ?? '');
    _bController = TextEditingController(text: widget.initialB ?? '');
    final op = normalizeOperation(widget.initialOp);
    _operation = (op != null && supportedOperations.contains(op)) ? op : '+';
    _aController.addListener(_syncUrl);
    _bController.addListener(_syncUrl);
  }

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _syncUrl() {
    final params = <String, String>{'op': _operation};
    final a = _aController.text.trim();
    final b = _bController.text.trim();
    if (a.isNotEmpty) params['a'] = a;
    if (b.isNotEmpty) params['b'] = b;
    final location = Uri(
      path: '/calculator',
      queryParameters: params,
    ).toString();
    if (location == _lastLocation) return;
    _lastLocation = location;
    context.replace(location);
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите число';
    if (parseNumber(value) == null) return 'Это не число';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final a = _aController.text.trim().replaceAll(',', '.');
    final b = _bController.text.trim().replaceAll(',', '.');
    context.go(
      '/calculator/result?a=$a&op=${Uri.encodeComponent(_operation)}&b=$b',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Калькулятор',
      maxWidth: 420,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _aController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Первое число',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _operation,
              decoration: const InputDecoration(
                labelText: 'Операция',
                border: OutlineInputBorder(),
              ),
              items: supportedOperations
                  .map(
                    (o) => DropdownMenuItem<String>(value: o, child: Text(o)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _operation = value ?? '+');
                _syncUrl();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Второе число',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Вычислить')),
          ],
        ),
      ),
    );
  }
}
