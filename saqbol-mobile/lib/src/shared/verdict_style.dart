import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colour and icon for a verdict in the current theme. The label that goes
/// with them is language dependent and comes from `AppStrings.verdictLabel`.
class VerdictStyle {
  const VerdictStyle({required this.color, required this.tint, required this.icon});

  final Color color;

  /// A soft tint of [color] for badges, icon backgrounds and the advice box.
  /// It is opaque (14% of [color] over the card surface), so [color] text on
  /// it keeps at least 4.5:1 whether it sits on a card or on the page.
  final Color tint;
  final IconData icon;

  static VerdictStyle of(BuildContext context, String verdict) {
    final c = context.saq;
    final (color, icon) = switch (verdict) {
      'scam' => (c.scam, Icons.gpp_bad_rounded),
      'suspicious' => (c.suspicious, Icons.warning_amber_rounded),
      _ => (c.safe, Icons.verified_user_rounded),
    };
    return VerdictStyle(
      color: color,
      tint: Color.alphaBlend(color.withValues(alpha: 0.14), c.surface),
      icon: icon,
    );
  }
}

/// Small rounded label with the verdict word, e.g. in lists.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict, required this.label});

  final String verdict;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = VerdictStyle.of(context, verdict);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: style.tint, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: style.color, fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Verdict icon in a tinted circle.
class VerdictAvatar extends StatelessWidget {
  const VerdictAvatar({super.key, required this.verdict, this.size = 44});

  final String verdict;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = VerdictStyle.of(context, verdict);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: style.tint, shape: BoxShape.circle),
      child: Icon(style.icon, color: style.color, size: size * 0.52),
    );
  }
}
