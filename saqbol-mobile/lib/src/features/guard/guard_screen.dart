import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../sms/widgets/verdict_card.dart';
import 'guard_controller.dart';

/// Automatic SMS protection: scan what is already on the device and keep
/// checking whatever arrives next.
class GuardScreen extends ConsumerStatefulWidget {
  const GuardScreen({super.key});

  @override
  ConsumerState<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends ConsumerState<GuardScreen> {
  @override
  void initState() {
    super.initState();
    // Permission can be revoked from system settings while the app is alive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guardControllerProvider.notifier).refreshPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(guardControllerProvider);
    final controller = ref.read(guardControllerProvider.notifier);

    if (state.status == GuardStatus.needsPermission) {
      return _PermissionPrompt(
        strings: strings,
        onGrant: controller.requestPermission,
        onOpenSettings: ref.read(smsReaderProvider).openSettings,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            value: state.watching,
            title: Text(strings.guardWatchTitle),
            subtitle: Text(strings.guardWatchSubtitle),
            // Once registered, the platform listener cannot be detached, so the
            // switch only ever moves forward; turning it off needs a restart.
            onChanged:
                state.watching ? null : (_) => controller.startWatching(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: state.status == GuardStatus.scanning
              ? null
              : () => controller.scanInbox(),
          icon: const Icon(Icons.search),
          label: Text(strings.guardScanButton),
        ),
        if (state.status == GuardStatus.scanning) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: state.total == 0 ? null : state.scanned / state.total,
          ),
          const SizedBox(height: 8),
          Center(child: Text('${state.scanned} / ${state.total}')),
        ],
        if (state.status == GuardStatus.failed) ...[
          const SizedBox(height: 12),
          Text(
            state.error ?? strings.guardScanFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        if (state.status == GuardStatus.ready && state.findings.isEmpty)
          Center(child: Text(strings.guardNothingFound))
        else
          for (final finding in state.findings)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VerdictCard(result: finding),
            ),
      ],
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({
    required this.strings,
    required this.onGrant,
    required this.onOpenSettings,
  });

  final AppStrings strings;
  final Future<void> Function() onGrant;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sms_failed_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            strings.guardPermissionTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            strings.guardPermissionBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onGrant,
            child: Text(strings.guardPermissionGrant),
          ),
          TextButton(
            onPressed: onOpenSettings,
            child: Text(strings.guardPermissionSettings),
          ),
        ],
      ),
    );
  }
}
