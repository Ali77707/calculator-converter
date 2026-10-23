import 'dart:async';

import 'package:flutter/material.dart';



class DebouncedTextField extends StatefulWidget {
  const DebouncedTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.hint,
    this.debounce = const Duration(milliseconds: 350),
    this.keyboardType,
    this.showClear = false,
  });

  final String label;
  final String? hint;
  final String value;
  final ValueChanged<String> onValueChanged;
  final Duration debounce;
  final TextInputType? keyboardType;

  final bool showClear;

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late final TextEditingController _controller;
  Timer? _timer;
  late bool _isEmpty;

  late String _lastEmitted;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _lastEmitted = widget.value;
    _isEmpty = _controller.text.isEmpty;
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant DebouncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _lastEmitted) {

      _timer?.cancel();
      _controller.text = widget.value;
      _lastEmitted = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final empty = _controller.text.isEmpty;

    if (empty != _isEmpty) setState(() => _isEmpty = empty);
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () {
      _lastEmitted = text;
      widget.onValueChanged(text);
    });
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    _lastEmitted = '';
    widget.onValueChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: !widget.showClear || _isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clear,
              ),
      ),
      onChanged: _onChanged,
    );
  }
}
