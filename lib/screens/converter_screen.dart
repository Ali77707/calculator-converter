import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/currency.dart';
import '../logic/numbers.dart';
import '../settings.dart';
import '../widgets/page_layout.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({
    super.key,
    this.initialAmount,
    this.initialFrom,
    this.initialTo,
  });

  final String? initialAmount;
  final String? initialFrom;
  final String? initialTo;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  late String _from;
  late String _to;
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
    _from = _validCode(widget.initialFrom) ?? currencyNames.keys.first;
    _to = _validCode(widget.initialTo) ?? currencyNames.keys.elementAt(1);
    _amountController.addListener(_syncUrl);
    if (_validCode(widget.initialFrom) == null ||
        _validCode(widget.initialTo) == null) {
      _restorePair();
    }
  }

  String? _validCode(String? code) =>
      (code != null && currencyNames.containsKey(code)) ? code : null;

  Future<void> _restorePair() async {
    final (from, to) = await Settings.loadCurrencyPair();
    if (!mounted) return;
    setState(() {
      _from = _validCode(from) ?? _from;
      _to = _validCode(to) ?? _to;
    });
    _syncUrl();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _syncUrl() {
    final params = <String, String>{'from': _from, 'to': _to};
    final amount = _amountController.text.trim();
    if (amount.isNotEmpty) params['amount'] = amount;
    final location = Uri(
      path: '/converter',
      queryParameters: params,
    ).toString();
    if (location == _lastLocation) return;
    _lastLocation = location;
    context.replace(location);
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите сумму';
    if (parseNumber(value) == null) return 'Это не число';
    return null;
  }

  Future<void> _savePair() => Settings.saveCurrencyPair(_from, _to);

  void _onFromChanged(String? value) {
    setState(() => _from = value ?? _from);
    _savePair();
    _syncUrl();
  }

  void _onToChanged(String? value) {
    setState(() => _to = value ?? _to);
    _savePair();
    _syncUrl();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountController.text.trim().replaceAll(',', '.');
    context.go(
      '/converter/result?amount=$amount'
      '&from=${Uri.encodeComponent(_from)}'
      '&to=${Uri.encodeComponent(_to)}',
    );
  }

  List<DropdownMenuItem<String>> _currencyItems() {
    return currencyNames.entries
        .map(
          (entry) => DropdownMenuItem<String>(
            value: entry.key,
            child: Text('${entry.key} — ${entry.value}'),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Конвертер валют',
      maxWidth: 420,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('from-$_from'),
              initialValue: _from,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Из валюты',
                border: OutlineInputBorder(),
              ),
              items: _currencyItems(),
              onChanged: _onFromChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('to-$_to'),
              initialValue: _to,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'В валюту',
                border: OutlineInputBorder(),
              ),
              items: _currencyItems(),
              onChanged: _onToChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                border: OutlineInputBorder(),
              ),
              validator: _amountValidator,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Конвертировать'),
            ),
          ],
        ),
      ),
    );
  }
}
