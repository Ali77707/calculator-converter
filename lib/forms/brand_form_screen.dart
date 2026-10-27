import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../repositories/brand_repository.dart';
import '../utils/validators.dart' as v;
import '../widgets/form_page_layout.dart';
import '../widgets/home_button.dart';
import '../widgets/list_state_view.dart';
import '../widgets/unsaved_changes_guard.dart';

class BrandFormScreen extends StatefulWidget {
  const BrandFormScreen({super.key, this.id});

  final int? id;

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();

  Brand? _brand;
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
    if (!_isEdit) {
      setState(() => _loading = false);
      return;
    }
    try {
      final brand = await context.read<BrandRepository>().findById(widget.id!);
      if (!mounted) return;
      setState(() {
        _brand = brand;
        _loading = false;
        if (brand != null) {
          _nameController.text = brand.name;
          _countryController.text = brand.country;
        }
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
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = context.read<BrandRepository>();
    final brand = Brand(
      id: _brand?.id ?? 0,
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
    );
    try {
      if (_isEdit) {
        await repository.update(brand);
      } else {
        await repository.create(brand);
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.go('/brands');
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
    if (_isEdit && _brand == null) {
      return Scaffold(
        appBar: AppBar(leading: const HomeButton()),
        body: const EmptyView(message: 'Марка не найдена'),
      );
    }

    return UnsavedChangesGuard(
      hasChanges: _dirty,
      child: FormPageLayout(
        title: _isEdit ? 'Редактирование марки' : 'Новая марка',
        formKey: _formKey,
        saving: _saving,
        onSave: _save,
        hasUnsavedChanges: _dirty,
        children: [
          FormSection(
            title: 'Основные данные',
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например, Toyota',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите название'),
                  (value) => v.minLength(value, 2),
                  (value) => v.maxLength(value, 50),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Страна',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _dirty = true),
                validator: (value) => v.combine(value, [
                  (value) => v.required(value, 'Введите страну'),
                  (value) => v.maxLength(value, 50),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
