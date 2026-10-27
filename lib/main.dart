import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/brand_repository.dart';
import 'repositories/car_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/in_memory_brand_repository.dart';
import 'repositories/in_memory_car_repository.dart';
import 'repositories/in_memory_client_repository.dart';
import 'repositories/in_memory_loyalty_card_repository.dart';
import 'repositories/in_memory_service_order_repository.dart';
import 'repositories/loyalty_card_repository.dart';
import 'repositories/service_order_repository.dart';
import 'router.dart';
import 'state/car_list_notifier.dart';
import 'state/client_list_notifier.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  await themeController.load();
  runApp(AutoServiceApp(prefs: prefs));
}

class AutoServiceApp extends StatelessWidget {
  const AutoServiceApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CarRepository>(
          create: (_) => InMemoryCarRepository(prefs: prefs),
        ),
        Provider<ClientRepository>(
          create: (_) => InMemoryClientRepository(prefs: prefs),
        ),
        Provider<BrandRepository>(
          create: (_) => InMemoryBrandRepository(prefs: prefs),
        ),
        Provider<LoyaltyCardRepository>(
          create: (_) => InMemoryLoyaltyCardRepository(prefs: prefs),
        ),
        Provider<ServiceOrderRepository>(
          create: (_) => InMemoryServiceOrderRepository(prefs: prefs),
        ),
        ChangeNotifierProvider<CarListNotifier>(
          create: (context) => CarListNotifier(context.read<CarRepository>()),
        ),
        ChangeNotifierProvider<ClientListNotifier>(
          create: (context) =>
              ClientListNotifier(context.read<ClientRepository>()),
        ),
      ],
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Автосервис',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.mode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 0, 0, 0),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 135, 135, 135),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
