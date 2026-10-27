import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'forms/brand_form_screen.dart';
import 'forms/car_form_screen.dart';
import 'forms/client_form_screen.dart';
import 'forms/loyalty_card_form_screen.dart';
import 'forms/service_order_form_screen.dart';
import 'screens/brand_detail_screen.dart';
import 'screens/brand_list_screen.dart';
import 'screens/car_detail_screen.dart';
import 'screens/car_list_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loyalty_card_detail_screen.dart';
import 'screens/loyalty_card_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/service_order_detail_screen.dart';
import 'screens/service_order_list_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/cars',
        builder: (context, state) =>
            CarListScreen(initialParams: state.uri.queryParameters),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CarFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                _editOrNotFound(state, (id) => CarFormScreen(id: id)),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                _detailOrNotFound(state, (id) => CarDetailScreen(id: id)),
          ),
        ],
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) =>
            ClientListScreen(initialParams: state.uri.queryParameters),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ClientFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                _editOrNotFound(state, (id) => ClientFormScreen(id: id)),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                _detailOrNotFound(state, (id) => ClientDetailScreen(id: id)),
          ),
        ],
      ),
      GoRoute(
        path: '/brands',
        builder: (context, state) => const BrandListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const BrandFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                _editOrNotFound(state, (id) => BrandFormScreen(id: id)),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                _detailOrNotFound(state, (id) => BrandDetailScreen(id: id)),
          ),
        ],
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const ServiceOrderListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ServiceOrderFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                _editOrNotFound(state, (id) => ServiceOrderFormScreen(id: id)),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => _detailOrNotFound(
              state,
              (id) => ServiceOrderDetailScreen(id: id),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/loyalty-cards',
        builder: (context, state) => const LoyaltyCardListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const LoyaltyCardFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                _editOrNotFound(state, (id) => LoyaltyCardFormScreen(id: id)),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => _detailOrNotFound(
              state,
              (id) => LoyaltyCardDetailScreen(id: id),
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
  return _editOrNotFound(state, build);
}

Widget _editOrNotFound(GoRouterState state, Widget Function(int id) build) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null) {
    return NotFoundScreen(location: state.uri.toString());
  }
  return build(id);
}

final GoRouter appRouter = createAppRouter();
