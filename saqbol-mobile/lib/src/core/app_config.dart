class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    return const AppConfig(apiBaseUrl: url);
  }

  String get apiPrefix => '$apiBaseUrl/api/v1';

  String get wsBaseUrl {
    if (apiBaseUrl.startsWith('https')) {
      return apiBaseUrl.replaceFirst('https', 'wss');
    }
    return apiBaseUrl.replaceFirst('http', 'ws');
  }
}
