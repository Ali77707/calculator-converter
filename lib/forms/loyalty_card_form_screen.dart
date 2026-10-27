import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/client.dart';
import '../models/loyalty_card.dart';
import '../repositories/client_repository.dart';
import '../repositories/loyalty_card_repository.dart';
import '../utils/validators.dart' as v;
import '../widgets/form_page_layout.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/unsaved_changes_guard.dart';

class LoyaltyCardFormScreen extends StatefulWidget {
  const LoyaltyCardFormScreen({super.key, this.id});

  final int? id;

  @override
  State<LoyaltyCardFormScreen> createState() => _LoyaltyCardFormScreenState();
}

class _LoyaltyCardFormScreenState extends State<LoyaltyCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _discountController = TextEditingController(text: '5');
  final _issuedAtController = TextEditingController();

  LoyaltyCard? _card;
  List<LoyaltyCard> _allCards = const [];
  List<Client> _clients = const [];
  int? _clientId;
  DateTime _issuedAt = DateTime.now();
  bool _active = true;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cardRepository = context.read<LoyaltyCardRepository>();
      final clientRepository = context.read<ClientRepository>();
      final cards = await cardRepository.findAll(includeDeleted: true);
      final clients = await clientRepository.findAll(includeDeleted: true);
      final card = _isEdit ? await cardRepository.findById(widget.id!) : null;
      if (!mounted) return;
      setState(() {
        _allCards = cards;
        _clients = clients;
        _card = card;
        _loading = false;
        if (card != null) {
          _clientId = card.clientId;
          _numberController.text = card.number;
          _discountController.text = '${card.discountPercent}';
          _issuedAt = card.issuedAt;
          _active = card.active;
        }
        _issuedAtController.text = ruDate(_issuedAt);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _discountController.dispose();
    _issuedAtController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    final base = v.combine(value, [
      (value) => v.required(value, 'Введите номер карты'),
      (value) => v.minLength(value, 4),
      (value) => v.maxLength(value, 30),
    ]);
    if (base != null) return base;
    final normalized = value!.trim().toLowerCase();
    final duplicate = _allCards.any(
      (card) =>
          card.id != _card?.id &&
          card.number.trim().toLowerCase() == normalized,
    );
    return duplicate ? 'Такой номер уже используется' : null;
  }

  String? _validateClient(int? value) {
    if (value == null) return 'Выберите клиента';
    final existing = _allCards.any(
      (card) => card.id != _card?.id && card.clientId == value,
    );
    return existing ? 'У клиента уже есть карта лояльности' : null;
  }

  Future<void> _pickIssuedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _issuedAt = picked;
        _issuedAtController.text = ruDate(picked);
        _dirty = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final card = LoyaltyCard(
      id: _card?.id ?? 0,
      clientId: _clientId!,
      number: _numberController.text.trim().toUpperCase(),
      issuedAt: _issuedAt,
      discountPercent: int.parse(_discountController.text.trim()),
      active: _active,
    );
    try {
      if (_isEdit) {
        await context.read<LoyaltyCardRepository>().update(card);
      } else {
        await context.read<LoyaltyCardRepository>().create(card);
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.go('/loyalty-cards');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    if (_isEdit && _card == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Карта не найдена'),
      );
    }

    return UnsavedChangesGuard(
      hasChanges: _dirty,
      child: FormPageLayout(
        title: _isEdit ? 'Редактирование карты' : 'Новая карта лояльности',
        formKey: _formKey,
        saving: _saving,
        onSave: _save,
        hasUnsavedChanges: _dirty,
        children: [
          FormSection(
            title: 'Карта лояльности',
            children: [
              DropdownButtonFormField<int>(
                initialValue: _clients.any((c) => c.id == _clientId)
                    ? _clientId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Клиент',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final client in _clients)
                    DropdownMenuItem(
                      value: client.id,
                      child: Text(
                        client.isDeleted
                            ? '${client.fullName.trim()} (удалён)'
                            : client.fullName.trim(),
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _clientId = value;
                    _dirty = true;
                  });
                },
                validator: _validateClient,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Номер карты',
                  hintText: 'LC-001',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _dirty = true),
                validator: _validateNumber,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Скидка, %',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _dirty = true),
                      validator: (value) => v.combine(value, [
                        (value) => v.required(value, 'Введите скидку'),
                        (value) => v.integer(value),
                        (value) => v.minInt(value, 0),
                        (value) => v.maxInt(value, 100),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: _issuedAtController,
                      decoration: const InputDecoration(
                        labelText: 'Дата выдачи',
                        border: OutlineInputBorder(),
                      ),
                      onTap: _pickIssuedAt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Карта активна'),
                value: _active,
                onChanged: (value) {
                  setState(() {
                    _active = value;
                    _dirty = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
