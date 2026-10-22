import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/preferences_storage.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/shared/theme_controller.dart';

class _MemoryThemeStorage implements ThemeStorage {
  _MemoryThemeStorage([this.name]);

  String? name;

  @override
  Future<String?> read() async => name;

  @override
  Future<void> save(String mode) async => name = mode;
}

ProviderContainer _container(_MemoryThemeStorage storage) {
  final container = ProviderContainer(
    overrides: [themeStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('stored names map back to modes, anything else is dark', () {
    expect(themeModeFromName('light'), ThemeMode.light);
    expect(themeModeFromName('system'), ThemeMode.system);
    expect(themeModeFromName('dark'), ThemeMode.dark);
    expect(themeModeFromName(null), ThemeMode.dark);
    expect(themeModeFromName('sepia'), ThemeMode.dark);
  });

  test('starts dark when nothing is stored', () async {
    final container = _container(_MemoryThemeStorage());
    expect(container.read(themeControllerProvider), ThemeMode.dark);
    await pumpEventQueue();
    expect(container.read(themeControllerProvider), ThemeMode.dark);
  });

  test('restores the theme chosen last time', () async {
    final container = _container(_MemoryThemeStorage('light'));
    container.read(themeControllerProvider);
    await pumpEventQueue();
    expect(container.read(themeControllerProvider), ThemeMode.light);
  });

  test('a choice is applied at once and saved', () async {
    final storage = _MemoryThemeStorage();
    final container = _container(storage);

    await container.read(themeControllerProvider.notifier).select(ThemeMode.system);

    expect(container.read(themeControllerProvider), ThemeMode.system);
    expect(storage.name, 'system');
  });

  test('a choice made before the stored theme is read is not overwritten', () async {
    final container = _container(_MemoryThemeStorage('light'));
    container.read(themeControllerProvider.notifier).select(ThemeMode.dark);
    await pumpEventQueue();
    expect(container.read(themeControllerProvider), ThemeMode.dark);
  });
}
