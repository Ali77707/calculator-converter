import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/client.dart';
import '../models/dictionaries.dart';
import '../models/loyalty_card.dart';
import '../repositories/client_repository.dart';
import '../repositories/loyalty_card_repository.dart';
import '../utils/validators.dart' as v;
import '../widgets/form_page_layout.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/unsaved_changes_guard.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.id});

  final int? id;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _discountController = TextEditingController(text: '5');
  final _issuedAtController = TextEditingController();

  Client? _client;
  LoyaltyCard? _card;
  List<Client> _allClients = const [];
  List<LoyaltyCard> _allCards = const [];
  DateTime _issuedAt = DateTime.now();
  bool _cardActive = true;
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
      final clientRepository = context.read<ClientRepository>();
      final cardRepository = context.read<LoyaltyCardRepository>();
      final clients = await clientRepository.findAll(includeDeleted: true);
      final cards = await cardRepository.findAll(includeDeleted: true);
      final client = _isEdit
          ? await clientRepository.findById(widget.id!)
          : null;
      final card = client == null
          ? null
          : await cardRepository.findByClient(client.id);
      if (!mounted) return;
      setState(() {
        _allClients = clients;
        _allCards = cards;
        _client = client;
        _card = card;
        _loading = false;
        if (client != null) {
          _lastNameController.text = client.lastName;
          _firstNameController.text = client.firstName;
          _middleNameController.text = client.middleName;
          _cityController.text = client.city;
          _phoneController.text = client.phone;
          _emailController.text = client.email;
        }
        if (card != null) {
          _cardNumberController.text = card.number;
          _discountController.text = '${card.discountPercent}';
          _issuedAt = card.issuedAt;
          _cardActive = card.active;
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
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cardNumberController.dispose();
    _discountController.dispose();
    _issuedAtController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final base = v.combine(value, [
      (value) => v.required(value, 'Введите email'),
      (value) => v.email(value),
      (value) => v.maxLength(value, 100),
    ]);
    if (base != null) return base;
    final normalized = value!.trim().toLowerCase();
    final duplicate = _allClients.any(
      (client) =>
          client.id != _client?.id &&
          client.email.trim().toLowerCase() == normalized,
    );
    return duplicate ? 'Этот email уже используется' : null;
  }

  String? _validateCardNumber(String? value) {
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
    return duplicate ? 'Такой номер карты уже существует' : null;
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
    final client = Client(
      id: _client?.id ?? 0,
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      city: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      registeredAt: _client?.registeredAt ?? DateTime.now(),
    );
    try {
      final clientRepository = context.read<ClientRepository>();
      final cardRepository = context.read<LoyaltyCardRepository>();
      final saved = _isEdit
          ? await clientRepository.update(client)
          : await clientRepository.create(client);
      final card = LoyaltyCard(
        id: _card?.id ?? 0,
        clientId: saved.id,
        number: _cardNumberController.text.trim().toUpperCase(),
        issuedAt: _issuedAt,
        discountPercent: int.parse(_discountController.text.trim()),
        active: _cardActive,
      );
      if (_card == null) {
        await cardRepository.create(card);
      } else {
        await cardRepository.update(card);
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.go('/clients');
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
    if (_isEdit && _client == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Клиент не найден'),
      );
    }

    return UnsavedChangesGuard(
      hasChanges: _dirty,
      child: FormPageLayout(
        title: _isEdit ? 'Редактирование клиента' : 'Новый клиент',
        formKey: _formKey,
        saving: _saving,
        onSave: _save,
        hasUnsavedChanges: _dirty,
        children: [
          FormSection(
            title: 'Личные данные',
            children: [
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите фамилию'),
                  (value) => v.minLength(value, 2),
                  (value) => v.maxLength(value, 50),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите имя'),
                  (value) => v.minLength(value, 2),
                  (value) => v.maxLength(value, 50),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Отчество',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.maxLength(value, 50),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: clientCities.contains(_cityController.text)
                    ? _cityController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final city in clientCities)
                    DropdownMenuItem(value: city, child: Text(city)),
                ],
                onChanged: (value) {
                  setState(() {
                    _cityController.text = value ?? '';
                    _dirty = true;
                  });
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Выберите город' : null,
              ),
            ],
          ),
          FormSection(
            title: 'Контакты',
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 900 000-00-00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите телефон'),
                  (value) => v.phone(value, 'Слишком короткий номер'),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _dirty = true),
                validator: _validateEmail,
              ),
            ],
          ),
          FormSection(
            title: 'Карта лояльности',
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Номер карты',
                  hintText: 'LC-001',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _dirty = true),
                validator: _validateCardNumber,
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
                      decoration: const InputDecoration(
                        labelText: 'Дата выдачи',
                        border: OutlineInputBorder(),
                      ),
                      controller: _issuedAtController,
                      onTap: _pickIssuedAt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Карта активна'),
                value: _cardActive,
                onChanged: (value) {
                  setState(() {
                    _cardActive = value;
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
