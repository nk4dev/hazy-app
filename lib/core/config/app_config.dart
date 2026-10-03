/// Runtime configuration, supplied via `--dart-define` at build/run time.
///
/// Neither value ships with a real default — Hazy's Clerk publishable key
/// and deployed backend URL are per-deployment secrets the human operator
/// must supply (see docs/ai/make-flutter-app.md §1–2 in the hazy repo).
class AppConfig {
  const AppConfig._();

  /// Base URL for `/v1/**`, e.g. `https://api.hazy.example.com/v1` or
  /// `http://10.0.2.2:8787/v1` for the Android emulator against a local
  /// `apps/api` dev server (`bun run dev`, port 8787).
  static const String apiBaseUrl = String.fromEnvironment(
    'HAZY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8787/v1',
  );

  /// Base URL for hazy note's own `/api` routes (the `apps/hazy-note` web
  /// app), used for notes — see `NoteApiClient`.
  static const String noteApiBaseUrl = String.fromEnvironment(
    'HAZY_NOTE_API_BASE_URL',
    defaultValue: 'https://note.hz.nknighta.me/api',
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
