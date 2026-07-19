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
