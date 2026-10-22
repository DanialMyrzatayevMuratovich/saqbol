import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// Maps a stored theme name back to a mode. Dark is the SaqBol default.
ThemeMode themeModeFromName(String? name) =>
    ThemeMode.values.asNameMap()[name] ?? ThemeMode.dark;

class ThemeController extends Notifier<ThemeMode> {
  bool _selected = false;

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.dark;
  }

  Future<void> _restore() async {
    final name = await ref.read(themeStorageProvider).read();
    // A choice made while the read was in flight wins over the stored one.
    if (name != null && !_selected) state = themeModeFromName(name);
  }

  Future<void> select(ThemeMode mode) async {
    _selected = true;
    state = mode;
    await ref.read(themeStorageProvider).save(mode.name);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
