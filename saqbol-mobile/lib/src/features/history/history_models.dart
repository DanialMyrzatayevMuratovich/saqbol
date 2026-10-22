class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.channel,
    required this.text,
    required this.sourceNumber,
    required this.probability,
    required this.verdict,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String channel;
  final String text;
  final String sourceNumber;
  final double probability;
  final String verdict;
  final String category;
  final DateTime createdAt;

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String? ?? '',
      channel: json['channel'] as String? ?? 'sms',
      text: json['text'] as String? ?? '',
      sourceNumber: json['source_number'] as String? ?? '',
      probability: (json['probability'] as num?)?.toDouble() ?? 0,
      verdict: json['verdict'] as String? ?? 'safe',
      category: json['category'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// The user's totals for a period, counted by the server over every check,
/// and their newest scam or suspicious messages.
class HistorySummary {
  const HistorySummary({
    required this.checked,
    required this.scam,
    required this.suspicious,
    required this.threats,
  });

  final int checked;
  final int scam;
  final int suspicious;
  final List<HistoryItem> threats;

  factory HistorySummary.fromJson(Map<String, dynamic> json) {
    return HistorySummary(
      checked: (json['checked'] as num?)?.toInt() ?? 0,
      scam: (json['scam'] as num?)?.toInt() ?? 0,
      suspicious: (json['suspicious'] as num?)?.toInt() ?? 0,
      threats: (json['threats'] as List<dynamic>? ?? [])
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
