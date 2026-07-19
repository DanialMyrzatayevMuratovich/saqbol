class SmsCheckResult {
  const SmsCheckResult({
    required this.messageId,
    required this.verdict,
    required this.probability,
    required this.category,
    required this.triggers,
    required this.advice,
    required this.modelVersion,
    required this.originalText,
  });

  final String messageId;
  final String verdict;
  final double probability;
  final String category;
  final List<String> triggers;
  final String advice;
  final String modelVersion;
  final String originalText;

  factory SmsCheckResult.fromJson(Map<String, dynamic> json, String originalText) {
    return SmsCheckResult(
      messageId: json['message_id'] as String? ?? '',
      verdict: json['verdict'] as String? ?? 'safe',
      probability: (json['probability'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      triggers: (json['triggers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      advice: json['advice'] as String? ?? '',
      modelVersion: json['model_version'] as String? ?? '',
      originalText: originalText,
    );
  }
}
