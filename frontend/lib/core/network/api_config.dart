class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Fallback URL if someone runs 'flutter run' without the flag
    defaultValue: 'http://localhost:8080',
  );
}
