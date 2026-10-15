import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'router.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  themeController.load();
  runApp(const CalcApp());
}

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Калькулятор и конвертер',
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
    );
  }
}
