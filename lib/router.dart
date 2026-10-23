import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/car_detail_screen.dart';
import 'screens/car_list_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/cars',
        builder: (context, state) => CarListScreen(
          initialParams: state.uri.queryParameters,
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => _detailOrNotFound(
              state,
              (id) => CarDetailScreen(id: id),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => ClientListScreen(
          initialParams: state.uri.queryParameters,
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => _detailOrNotFound(
              state,
              (id) => ClientDetailScreen(id: id),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

Widget _detailOrNotFound(GoRouterState state, Widget Function(int id) build) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null) {
    return NotFoundScreen(location: state.uri.toString());
  }
  return build(id);
}

final GoRouter appRouter = createAppRouter();
