import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../auth/auth_controller.dart';
import '../history/history_screen.dart';
import '../sms/sms_check_screen.dart';
import '../voice/voice_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final titles = [strings.smsTitle, strings.callTitle, strings.tabHistory];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          TextButton(
            onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
            child: Text(ref.watch(localeControllerProvider) == AppLocale.ru ? 'ҚАЗ' : 'РУС'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: strings.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          SmsCheckScreen(),
          VoiceScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.sms_outlined), label: strings.tabSms),
          NavigationDestination(icon: const Icon(Icons.mic_none), label: strings.tabCall),
          NavigationDestination(icon: const Icon(Icons.history), label: strings.tabHistory),
        ],
      ),
    );
  }
}
