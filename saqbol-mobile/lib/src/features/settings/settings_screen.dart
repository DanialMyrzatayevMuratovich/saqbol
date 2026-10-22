import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../../shared/brand.dart';
import '../../shared/theme_controller.dart';
import '../auth/auth_controller.dart';
import '../guard/guard_controller.dart';
import 'inbox_scan_screen.dart';

/// Protection switches, appearance, privacy and the account.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  /// SMS access and call screening exist on Android only.
  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The user may come back from system settings with a permission or the
  // call-screening role granted or revoked.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!_android || !mounted) return;
    final controller = ref.read(guardControllerProvider.notifier);
    controller.refreshPermission();
    controller.refreshCallGuard();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final guard = ref.watch(guardControllerProvider);
    final controller = ref.read(guardControllerProvider.notifier);
    final c = context.saq;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.xl),
      children: [
        Row(
          children: [
            const SaqLogo(size: 52),
            const SizedBox(width: Gap.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SaqBol', style: text.titleLarge),
                  Text(strings.profileSubtitle, style: text.bodyMedium?.copyWith(color: c.muted)),
                ],
              ),
            ),
          ],
        ),
        _SectionTitle(strings.sectionProtection),
        if (_android && guard.status == GuardStatus.needsPermission) ...[
          _PermissionCard(
            strings: strings,
            onGrant: controller.requestPermission,
            onOpenSettings: ref.read(smsReaderProvider).openSettings,
          ),
          const SizedBox(height: Gap.s),
        ],
        _ProtectionTile(
          icon: Icons.sms_rounded,
          title: strings.guardWatchTitle,
          subtitle: strings.guardWatchSubtitle,
          on: guard.watching,
          available: _android,
          strings: strings,
          // Once registered, the platform listener cannot be detached, so this
          // only ever turns on; it shows a badge instead of a locked switch.
          onTurnOn: controller.startWatching,
        ),
        const SizedBox(height: Gap.s),
        _ProtectionTile(
          icon: Icons.phone_in_talk_rounded,
          title: strings.guardCallTitle,
          subtitle: strings.guardCallSubtitle,
          on: guard.callGuard,
          available: _android,
          strings: strings,
          onTurnOn: controller.enableCallGuard,
        ),
        if (_android) ...[
          const SizedBox(height: Gap.s),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.xs),
              leading: _IconBubble(icon: Icons.manage_search_rounded, color: c.accent),
              title: Text(strings.guardScanButton),
              subtitle: Text(strings.scanInboxSubtitle),
              trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InboxScanScreen())),
            ),
          ),
        ],
        _SectionTitle(strings.sectionAppearance),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.themeLabel, style: text.titleSmall),
                const SizedBox(height: Gap.s),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(strings.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, label: Text(strings.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(strings.themeDark)),
                  ],
                  selected: {ref.watch(themeControllerProvider)},
                  onSelectionChanged: (selection) => ref.read(themeControllerProvider.notifier).select(selection.first),
                ),
                const SizedBox(height: Gap.l),
                Text(strings.languageLabel, style: text.titleSmall),
                const SizedBox(height: Gap.s),
                SegmentedButton<AppLocale>(
                  showSelectedIcon: false,
                  // Each language under its own name, so it can be found whatever
                  // the interface is currently set to.
                  segments: const [
                    ButtonSegment(value: AppLocale.kk, label: Text('Қазақша')),
                    ButtonSegment(value: AppLocale.ru, label: Text('Русский')),
                    ButtonSegment(value: AppLocale.en, label: Text('English')),
                  ],
                  selected: {ref.watch(localeControllerProvider)},
                  onSelectionChanged: (selection) => ref.read(localeControllerProvider.notifier).select(selection.first),
                ),
              ],
            ),
          ),
        ),
        _SectionTitle(strings.sectionPrivacy),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBubble(icon: Icons.lock_rounded, color: c.safe),
                const SizedBox(width: Gap.l),
                Expanded(child: Text(strings.privacyBody, style: text.bodyMedium)),
              ],
            ),
          ),
        ),
        _SectionTitle(strings.sectionAccount),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.xs),
            leading: _IconBubble(icon: Icons.logout_rounded, color: c.scam),
            title: Text(strings.logout, style: TextStyle(color: c.scam, fontWeight: FontWeight.w600)),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xl, 0, Gap.s),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.saq.muted)),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color),
    );
  }
}

/// One protection feature. Off: a “Turn on” button. On: a green badge, since
/// neither feature can be switched off from inside the app.
class _ProtectionTile extends StatelessWidget {
  const _ProtectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.on,
    required this.available,
    required this.strings,
    required this.onTurnOn,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool on;
  final bool available;
  final AppStrings strings;
  final Future<void> Function() onTurnOn;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;

    final Widget status;
    if (!available) {
      status = Text(strings.androidOnly, style: text.bodySmall);
    } else if (on) {
      status = Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 6),
        decoration: BoxDecoration(color: c.safe.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 18, color: c.safe),
            const SizedBox(width: Gap.xs),
            Text(strings.enabled, style: TextStyle(color: c.safe, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    } else {
      status = FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: Gap.l)),
        onPressed: onTurnOn,
        child: Text(strings.turnOn),
      );
    }

    // The status sits under the text, so long titles keep the full width.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBubble(icon: icon, color: on ? c.safe : c.accent),
            const SizedBox(width: Gap.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium?.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: text.bodySmall),
                  const SizedBox(height: Gap.m),
                  status,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.strings, required this.onGrant, required this.onOpenSettings});

  final AppStrings strings;
  final Future<void> Function() onGrant;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    return Card(
      color: c.suspicious.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sms_failed_rounded, color: c.suspicious),
                const SizedBox(width: Gap.s),
                Expanded(child: Text(strings.guardPermissionTitle, style: text.titleMedium)),
              ],
            ),
            const SizedBox(height: Gap.s),
            Text(strings.guardPermissionBody, style: text.bodyMedium),
            const SizedBox(height: Gap.m),
            Row(
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: onGrant,
                  child: Text(strings.guardPermissionGrant),
                ),
                const SizedBox(width: Gap.s),
                TextButton(onPressed: onOpenSettings, child: Text(strings.guardPermissionSettings)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
