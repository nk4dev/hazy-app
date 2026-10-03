/// Mirrors the `error` branch of Hazy's response envelope (see
/// docs/ai/make-flutter-app.md §3–4 in the hazy repo).
///
/// Every `/v1/**` call surfaces failures through this type — never a
/// raw [DioException] — so callers always branch on `code`/`message`
/// rather than HTTP status alone.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.httpStatus,
  });

  /// A transport-level failure that never reached the envelope (timeout, no
  /// connection, malformed JSON, etc).
  factory ApiException.network(String message) => ApiException(
        code: 'network_error',
        message: message,
      );

  /// The request was never sent because the device is known to be offline
  /// (see `OfflineMode`). A client-side code, not part of the backend
  /// contract.
  factory ApiException.offline() => const ApiException(
        code: 'offline',
        message: 'You are offline.',
      );

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? httpStatus;

  bool get isOffline => code == 'offline';
  bool get isNetworkError => code == 'network_error' || isOffline;
  bool get isUnauthorized => code == 'unauthorized';
  bool get isNotFound => code == 'not_found';
  bool get isValidationError => code == 'validation_error';
  bool get isServiceNotConfigured => code == 'service_not_configured';
  bool get isImageFetchFailed => code == 'image_fetch_failed';

  @override
  String toString() => 'ApiException($code): $message';
}
