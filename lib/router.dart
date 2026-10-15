import 'package:go_router/go_router.dart';

import 'logic/calculator.dart';
import 'logic/currency.dart';
import 'screens/calculator_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/result_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/calculator',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return CalculatorScreen(
            initialA: q['a'],
            initialOp: q['op'],
            initialB: q['b'],
          );
        },
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final result = calculate(a: q['a'], op: q['op'], b: q['b']);
              return ResultScreen(
                title: 'Результат вычисления',
                expression:
                    '${q['a'] ?? '?'} '
                    '${normalizeOperation(q['op']) ?? '?'} '
                    '${q['b'] ?? '?'}',
                result: result,
                rawParams: q,
                backPath: '/calculator',
                backLabel: 'К калькулятору',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/converter',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return ConverterScreen(
            initialAmount: q['amount'],
            initialFrom: q['from'],
            initialTo: q['to'],
          );
        },
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final result = convertCurrency(
                amount: q['amount'],
                from: q['from'],
                to: q['to'],
              );
              return ResultScreen(
                title: 'Результат конвертации',
                expression:
                    '${q['amount'] ?? '?'} ${q['from'] ?? '?'} → ${q['to'] ?? '?'}',
                result: result,
                rawParams: q,
                backPath: '/converter',
                backLabel: 'К конвертеру',
                fractionDigits: 2,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

final GoRouter appRouter = createAppRouter();
