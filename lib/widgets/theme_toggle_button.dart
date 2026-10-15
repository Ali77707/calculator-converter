import 'package:flutter/material.dart';

import '../theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return IconButton(
          tooltip: themeController.isDark
              ? 'Включить светлую тему'
              : 'Включить тёмную тему',
          onPressed: themeController.toggle,
          icon: Icon(
            themeController.isDark ? Icons.light_mode : Icons.dark_mode,
          ),
        );
      },
    );
  }
}
