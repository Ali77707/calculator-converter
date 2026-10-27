import 'package:flutter/material.dart';

import 'home_button.dart';
import 'theme_toggle_button.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 520,
    this.showHomeButton = true,
    this.actions,
  });

  final String title;

  final Widget child;

  final double maxWidth;

  final bool showHomeButton;

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showHomeButton ? const HomeButton() : null,
        actions: [if (actions != null) ...actions!, const ThemeToggleButton()],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = (constraints.maxHeight - 48).clamp(
              0.0,
              double.infinity,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
