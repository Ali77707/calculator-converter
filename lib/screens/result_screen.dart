import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/numbers.dart';
import '../widgets/page_layout.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.title,
    required this.expression,
    required this.result,
    required this.rawParams,
    required this.backPath,
    required this.backLabel,
    this.fractionDigits = 6,
  });

  final String title;

  final String expression;

  final OperationResult result;

  final Map<String, String> rawParams;

  final String backPath;

  final String backLabel;

  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = result is OperationSuccess;

    return PageLayout(
      title: title,
      maxWidth: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    expression,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isSuccess)
                    SelectableText(
                      formatNumber(
                        (result as OperationSuccess).value,
                        fractionDigits: fractionDigits,
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            (result as OperationFailure).message,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AddressParams(params: rawParams),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go(backPath),
            label: Text(backLabel),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            label: const Text('На главную'),
          ),
        ],
      ),
    );
  }
}

class _AddressParams extends StatelessWidget {
  const _AddressParams({required this.params});

  final Map<String, String> params;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Переменные', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (params.isEmpty)
              Text('Параметры отсутствуют', style: theme.textTheme.bodyMedium)
            else
              ...params.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${entry.key} = ${entry.value}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
