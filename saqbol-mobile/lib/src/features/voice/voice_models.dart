class CallAlert {
  const CallAlert({
    required this.verdict,
    required this.probability,
    required this.category,
    required this.triggers,
    required this.advice,
    required this.alert,
  });

  final String verdict;
  final double probability;
  final String category;
  final List<String> triggers;
  final String advice;
  final bool alert;

  factory CallAlert.fromJson(Map<String, dynamic> json) {
    return CallAlert(
      verdict: json['verdict'] as String? ?? 'safe',
      probability: (json['probability'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      triggers: (json['triggers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      advice: json['advice'] as String? ?? '',
      alert: json['alert'] as bool? ?? false,
    );
  }
}
