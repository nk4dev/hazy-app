import 'package:dio/dio.dart';

import '../../models/note.dart';
import '../config/app_config.dart';
import '../connectivity/offline_mode.dart';
import 'api_exception.dart';

/// Client for hazy note's own `/api/*` routes (`apps/hazy-note` — Next.js
/// route handlers, deployed separately from the `/v1` Worker).
///
/// This is a deliberate exception to "the app only talks to `/v1`": notes
/// have no `/v1` endpoints, so the app reuses the web app's API with the
/// same Clerk session token. Two differences from [ApiClient] follow from
/// that:
///  - responses are bare JSON, not the `{ data } / { error }` envelope;
///  - an unauthenticated request is answered with Clerk's HTML 404 rewrite
///    rather than a JSON 401.
/// Failures still surface as [ApiException] so UI code is shared.
class NoteApiClient {
  NoteApiClient({required Future<String?> Function() getToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.noteApiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (OfflineMode.isOffline) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: ApiException.offline(),
              ),
            );
          }
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Future<T> _send<T>(Future<Response<dynamic>> request) async {
    try {
      final response = await request;
      final data = response.data;
      if (data is T) return data;
      throw ApiException.network('Malformed response from hazy note');
    } on DioException catch (e) {
      if (e.error case final ApiException offline) throw offline;
      final response = e.response;
      if (response == null) {
        throw ApiException.network(e.message ?? 'Network request failed');
      }
      final status = response.statusCode;
      final data = response.data;
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : null;
      // Clerk answers a missing/invalid session with an HTML 404, while a
      // genuinely missing note is a JSON `{ error: "not found" }`.
      if (status == 401 || (status == 404 && message == null)) {
        throw ApiException(
          code: 'unauthorized',
          message: 'Sign in required.',
          httpStatus: status,
        );
      }
      if (status == 404) {
        throw ApiException(
          code: 'not_found',
          message: message ?? 'Not found.',
          httpStatus: status,
        );
      }
      throw ApiException(
        code: status == 400 ? 'validation_error' : 'internal_error',
        message: message ?? 'Something went wrong.',
        httpStatus: status,
      );
    }
  }

  Future<List<Note>> listNotes() async {
    final json = await _send<List<dynamic>>(_dio.get('/notes'));
    return json
        .whereType<Map<String, dynamic>>()
        .map(Note.fromJson)
        .toList();
  }

  Future<Note> getNote(String id) async {
    final json = await _send<Map<String, dynamic>>(_dio.get('/notes/$id'));
    return Note.fromJson(json);
  }

  /// [fields] is the same shape `PATCH /api/notes/:id` takes — any of
  /// `title`, `status`, `projectId`, `body`, `suggestions`, `tags`,
  /// `sources`.
  Future<Note> createNote(Map<String, dynamic> fields) async {
    final json = await _send<Map<String, dynamic>>(
      _dio.post('/notes', data: fields),
    );
    return Note.fromJson(json);
  }

  Future<Note> updateNote(String id, Map<String, dynamic> fields) async {
    final json = await _send<Map<String, dynamic>>(
      _dio.patch('/notes/$id', data: fields),
    );
    return Note.fromJson(json);
  }

  Future<void> deleteNote(String id) =>
      _send<Map<String, dynamic>>(_dio.delete('/notes/$id'));

  /// [action] is `"accept"` or `"dismiss"`. Accepting only drops the
  /// suggestion server-side — the caller inserts its text into the body.
  Future<Note> resolveSuggestion(
    String noteId,
    String suggestionId,
    String action,
  ) async {
    final json = await _send<Map<String, dynamic>>(
      _dio.post(
        '/notes/$noteId/suggestion',
        data: {'id': suggestionId, 'action': action},
      ),
    );
    return Note.fromJson(json);
  }

  Future<List<NoteProject>> listProjects() async {
    final json = await _send<List<dynamic>>(_dio.get('/projects'));
    return json
        .whereType<Map<String, dynamic>>()
        .map(NoteProject.fromJson)
        .toList();
  }
}
