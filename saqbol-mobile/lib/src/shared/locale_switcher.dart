import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/strings.dart';
import 'app_theme.dart';

/// App-bar language picker. Languages are listed under their own names so the
/// right one can be found whatever the interface is currently set to.
class LocaleSwitcher extends ConsumerWidget {
  const LocaleSwitcher({super.key});

  static const _codes = {
    AppLocale.ru: 'РУС',
    AppLocale.kk: 'ҚАЗ',
    AppLocale.en: 'ENG',
  };

  static const _names = {
    AppLocale.ru: 'Русский',
    AppLocale.kk: 'Қазақша',
    AppLocale.en: 'English',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    final accent = context.saq.accent;

    return PopupMenuButton<AppLocale>(
      initialValue: current,
      onSelected: (locale) =>
          ref.read(localeControllerProvider.notifier).select(locale),
      itemBuilder: (context) => [
        for (final locale in AppLocale.values)
          PopupMenuItem(value: locale, child: Text(_names[locale]!)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              _codes[current]!,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
