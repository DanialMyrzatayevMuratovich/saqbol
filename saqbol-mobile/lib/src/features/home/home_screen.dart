import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/brand.dart';
import '../../shared/theme_toggle.dart';
import '../dashboard/dashboard_screen.dart';
import '../guard/guard_controller.dart';
import '../history/history_providers.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../sms/sms_check_screen.dart';
import '../voice/voice_screen.dart';
import 'shell_tab.dart';

/// The main screen: five tabs that keep their state while switching.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Restart the SMS listener the user had turned on and re-read the call
    // screening role, which can be revoked in system settings.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guardControllerProvider.notifier).restore();
    });
  }

  void _select(ShellTab tab) {
    HapticFeedback.selectionClick();
    if (tab == ShellTab.home || tab == ShellTab.history) {
      ref.invalidate(historyProvider);
      ref.invalidate(historySummaryProvider);
    }
    ref.read(shellTabProvider.notifier).go(tab);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final tab = ref.watch(shellTabProvider);

    final titles = {
      ShellTab.home: 'SaqBol',
      ShellTab.check: strings.smsTitle,
      ShellTab.call: strings.callTitle,
      ShellTab.history: strings.tabHistory,
      ShellTab.settings: strings.tabSettings,
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            if (tab == ShellTab.home) ...[const SaqLogo(size: 30), const SizedBox(width: 10)],
            Text(titles[tab]!),
          ],
        ),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: IndexedStack(
        index: tab.index,
        children: const [
          DashboardScreen(),
          SmsCheckScreen(),
          VoiceScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) => _select(ShellTab.values[index]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: strings.tabHome),
          NavigationDestination(icon: const Icon(Icons.sms_outlined), selectedIcon: const Icon(Icons.sms_rounded), label: strings.tabSms),
          NavigationDestination(icon: const Icon(Icons.mic_none_rounded), selectedIcon: const Icon(Icons.mic_rounded), label: strings.tabCall),
          NavigationDestination(icon: const Icon(Icons.history_rounded), selectedIcon: const Icon(Icons.history_rounded), label: strings.tabHistory),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: strings.tabSettings),
        ],
      ),
    );
  }
}
