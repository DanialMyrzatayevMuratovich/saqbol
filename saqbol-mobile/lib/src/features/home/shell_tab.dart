import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tabs of the main screen, in navigation-bar order.
enum ShellTab { home, check, call, history, settings }

class ShellTabController extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.home;

  void go(ShellTab tab) => state = tab;
}

final shellTabProvider = NotifierProvider<ShellTabController, ShellTab>(ShellTabController.new);
