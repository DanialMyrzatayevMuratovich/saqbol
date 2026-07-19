import 'package:flutter/material.dart';

class VerdictStyle {
  const VerdictStyle({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  static VerdictStyle of(String verdict) {
    switch (verdict) {
      case 'scam':
        return const VerdictStyle(
          label: 'Мошенничество',
          color: Color(0xFFD32F2F),
          icon: Icons.gpp_bad,
        );
      case 'suspicious':
        return const VerdictStyle(
          label: 'Подозрительно',
          color: Color(0xFFF57C00),
          icon: Icons.warning_amber,
        );
      default:
        return const VerdictStyle(
          label: 'Безопасно',
          color: Color(0xFF2E7D32),
          icon: Icons.verified_user,
        );
    }
  }
}

const categoryLabels = {
  'fake_bank': 'Фейк-банк',
  'phishing': 'Фишинг',
  'fake_prize': 'Фейк-приз',
  'fake_police': 'Фейк-полиция',
  'kaspi_scam': 'Kaspi-скам',
  'other': 'Другое',
};

String categoryLabel(String category) => categoryLabels[category] ?? category;
