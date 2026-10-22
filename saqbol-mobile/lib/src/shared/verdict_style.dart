import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colour and icon for a verdict. The label that goes with them is language
/// dependent and comes from `AppStrings.verdictLabel`.
class VerdictStyle {
  const VerdictStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static VerdictStyle of(String verdict) {
    switch (verdict) {
      case 'scam':
        return const VerdictStyle(
          color: AppColors.scam,
          icon: Icons.gpp_bad,
        );
      case 'suspicious':
        return const VerdictStyle(
          color: AppColors.suspicious,
          icon: Icons.warning_amber,
        );
      default:
        return const VerdictStyle(
          color: AppColors.safe,
          icon: Icons.verified_user,
        );
    }
  }
}
