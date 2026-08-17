/// Runtime configuration, supplied via `--dart-define` at build/run time.
///
/// Neither value ships with a real default — Hazy's Clerk publishable key
/// and deployed backend URL are per-deployment secrets the human operator
/// must supply (see docs/ai/make-flutter-app.md §1–2 in the hazy repo).
class AppConfig {
  const AppConfig._();

  /// Base URL for `/api/v1/**`, e.g. `https://hazy.example.com/api/v1` or
  /// `http://10.0.2.2:3000/api/v1` for the Android emulator against a local
  /// `next dev` server.
  static const String apiBaseUrl = String.fromEnvironment(
    'HAZY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  /// Clerk publishable key for this project's Clerk instance.
  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
  );

  /// False until a real Clerk key has been supplied — gates the app behind
  /// a "not configured" screen instead of letting the Clerk SDK fail on an
  /// empty key.
  static bool get isConfigured => clerkPublishableKey.isNotEmpty;
}
