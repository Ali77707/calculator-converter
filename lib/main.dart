import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/car_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/in_memory_car_repository.dart';
import 'repositories/in_memory_client_repository.dart';
import 'router.dart';
import 'state/car_list_notifier.dart';
import 'state/client_list_notifier.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  themeController.load();
  runApp(const AutoServiceApp());
}

class AutoServiceApp extends StatelessWidget {
  const AutoServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CarRepository>(create: (_) => InMemoryCarRepository()),
        Provider<ClientRepository>(create: (_) => InMemoryClientRepository()),
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
