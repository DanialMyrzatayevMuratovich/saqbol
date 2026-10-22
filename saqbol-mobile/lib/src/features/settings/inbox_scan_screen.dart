import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../guard/guard_controller.dart';
import '../sms/widgets/verdict_card.dart';

/// Checks the messages already on the phone and lists only the dangerous ones.
/// The scan starts as soon as the screen opens.
class InboxScanScreen extends ConsumerStatefulWidget {
  const InboxScanScreen({super.key});

  @override
  ConsumerState<InboxScanScreen> createState() => _InboxScanScreenState();
}

class _InboxScanScreenState extends ConsumerState<InboxScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(guardControllerProvider).status != GuardStatus.scanning) {
        ref.read(guardControllerProvider.notifier).scanInbox();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(guardControllerProvider);
    final controller = ref.read(guardControllerProvider.notifier);
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    final scanning = state.status == GuardStatus.scanning;

    return Scaffold(
      appBar: AppBar(title: Text(strings.guardScanButton)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.xl),
        children: [
          if (state.status == GuardStatus.needsPermission)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.guardPermissionTitle, style: text.titleMedium),
                    const SizedBox(height: Gap.s),
                    Text(strings.guardPermissionBody, style: text.bodyMedium),
                    const SizedBox(height: Gap.m),
                    FilledButton(
                      onPressed: () async {
                        await controller.requestPermission();
                        if (ref.read(guardControllerProvider).status != GuardStatus.needsPermission) {
                          await controller.scanInbox();
                        }
                      },
                      child: Text(strings.guardPermissionGrant),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        switch (state.status) {
                          GuardStatus.failed => Icon(Icons.error_outline_rounded, color: c.scam),
                          GuardStatus.ready => Icon(Icons.task_alt_rounded, color: c.safe),
                          _ => Icon(Icons.manage_search_rounded, color: c.accent),
                        },
                        const SizedBox(width: Gap.m),
                        Expanded(child: Text(strings.scanInboxSubtitle, style: text.bodyMedium)),
                        Text('${state.scanned} / ${state.total}', style: text.titleSmall),
                      ],
                    ),
                    const SizedBox(height: Gap.m),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: scanning && state.total == 0 ? null : (state.total == 0 ? 1 : state.scanned / state.total),
                        backgroundColor: c.surfaceRaised,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.status == GuardStatus.failed) ...[
              const SizedBox(height: Gap.m),
              Text(state.error ?? strings.guardScanFailed, style: TextStyle(color: c.scam)),
            ],
            if (!scanning) ...[
              const SizedBox(height: Gap.s),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.scanInbox,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(strings.guardScanButton),
                ),
              ),
            ],
            const SizedBox(height: Gap.s),
            if (state.status == GuardStatus.ready && state.findings.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.xl),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: c.safe),
                      const SizedBox(width: Gap.m),
                      Expanded(child: Text(strings.guardNothingFound, style: text.bodyLarge)),
                    ],
                  ),
                ),
              )
            else
              for (final finding in state.findings)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.m),
                  child: VerdictCard(result: finding),
                ),
          ],
        ],
      ),
    );
  }
}
