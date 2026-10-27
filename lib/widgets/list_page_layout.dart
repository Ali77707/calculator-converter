import 'package:flutter/material.dart';

import 'home_button.dart';
import 'theme_toggle_button.dart';

class ListPageLayout extends StatelessWidget {
  const ListPageLayout({
    super.key,
    required this.title,
    required this.toolbar,
    required this.filters,
    required this.body,
    required this.pagination,
    this.maxContentWidth = 1400,
  });

  final String title;
  final Widget toolbar;
  final Widget filters;
  final Widget body;
  final Widget pagination;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const HomeButton(),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  const SizedBox(height: 12),
                  filters,
                  const SizedBox(height: 12),
                  Expanded(child: body),
                  pagination,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
