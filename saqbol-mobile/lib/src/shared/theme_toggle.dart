import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/strings.dart';
import 'theme_controller.dart';

/// App-bar button that flips between the light and the dark theme.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: ref.watch(stringsProvider).toggleTheme,
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      onPressed: () => ref
          .read(themeControllerProvider.notifier)
          .select(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
