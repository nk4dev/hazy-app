import 'package:dio/dio.dart';

import '../../models/ask.dart';
import '../../models/collection.dart';
import '../../models/paginated_response.dart';
import '../../models/read_later.dart';
import '../../models/saved_url.dart';
import '../../models/user_me.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper over `/api/v1/**` (see docs/ai/make-flutter-app.md in the
/// hazy repo). Every method returns decoded models or throws
/// [ApiException] — never a raw [DioException] — per the envelope contract
/// in §3–4 of that brief.
class ApiClient {
  ApiClient({required Future<String?> Function() getToken})
      : _getToken = getToken,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            // POST /items fetches metadata server-side with an ~8s budget.
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final Future<String?> Function() _getToken;

  Future<Map<String, dynamic>> _unwrap(Future<Response> request) async {
    late final Response response;
    try {
      response = await request;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['error'] is Map) {
        throw _errorFrom(data, e.response?.statusCode);
      }
      throw ApiException.network(e.message ?? 'Network request failed');
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['error'] is Map) {
        throw _errorFrom(data, response.statusCode);
      }
      if (data.containsKey('data')) {
        return data['data'] as Map<String, dynamic>;
      }
    }
    throw ApiException.network('Malformed response from server');
  }

  ApiException _errorFrom(Map<String, dynamic> data, int? status) {
    final error = data['error'] as Map<String, dynamic>;
    return ApiException(
      code: error['code'] as String? ?? 'internal_error',
      message: error['message'] as String? ?? 'Something went wrong.',
      details: (error['details'] as Map<String, dynamic>?),
      httpStatus: status,
    );
  }

  // ---- Saved items --------------------------------------------------

  Future<SavedUrl> saveUrl(String url) async {
    final json = await _unwrap(_dio.post('/items', data: {'url': url}));
    return SavedUrl.fromJson(json);
  }

  Future<PaginatedResponse<SavedUrl>> listItems({
    String? cursor,
    int limit = 30,
    String sort = 'newest',
  }) async {
    final json = await _unwrap(
      _dio.get(
        '/items',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          'sort': sort,
        },
      ),
    );
    return PaginatedResponse.fromJson(json, SavedUrl.fromJson);
  }

  Future<SavedUrl> getItem(String id) async {
    final json = await _unwrap(_dio.get('/items/$id'));
    return SavedUrl.fromJson(json);
  }

  Future<SavedUrl> updateItem(
    String id, {
    String? title,
    String? summary,
  }) async {
    final json = await _unwrap(
      _dio.patch(
        '/items/$id',
        data: {
          if (title != null) 'title': title,
          if (summary != null) 'summary': summary,
        },
      ),
    );
    return SavedUrl.fromJson(json);
  }

  Future<void> deleteItem(String id) => _unwrap(_dio.delete('/items/$id'));

  Future<SavedUrl> refetchItem(String id) async {
    final json = await _unwrap(_dio.post('/items/$id/refetch'));
    return SavedUrl.fromJson(json);
  }

  Future<SavedUrl> summarizeItem(String id) async {
    final json = await _unwrap(_dio.post('/items/$id/summarize'));
    return SavedUrl.fromJson(json);
  }

  // ---- Search ---------------------------------------------------------

  Future<List<SavedUrl>> search(String query, {int limit = 20}) async {
    final json = await _unwrap(
      _dio.get(
        '/search',
        queryParameters: {'q': query, 'limit': limit},
      ),
    );
    return (json['items'] as List<dynamic>)
        .map((e) => SavedUrl.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Read later -------------------------------------------------------

  Future<ReadLaterQueue> getReadLaterQueue() async {
    final json = await _unwrap(_dio.get('/read-later'));
    return ReadLaterQueue.fromJson(json);
  }

  Future<void> updateReadLaterStatus(
    String itemId, {
    required ReadLaterStatus status,
    DateTime? snoozedUntil,
  }) {
    return _unwrap(
      _dio.patch(
        '/read-later/$itemId',
        data: {
          'status': status.toJson(),
          if (snoozedUntil != null)
            'snoozedUntil': snoozedUntil.toUtc().toIso8601String(),
        },
      ),
    );
  }

  Future<ReadLaterStats> getReadLaterStats() async {
    final json = await _unwrap(_dio.get('/read-later/stats'));
    return ReadLaterStats.fromJson(json);
  }

  // ---- Collections --------------------------------------------------

  Future<List<Collection>> listCollections() async {
    final json = await _unwrap(_dio.get('/collections'));
    return (json['items'] as List<dynamic>)
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Collection> createCollection({
    required String name,
    String? description,
    String? color,
  }) async {
    final json = await _unwrap(
      _dio.post(
        '/collections',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (color != null) 'color': color,
        },
      ),
    );
    return Collection.fromJson(json);
  }

  Future<CollectionDetail> getCollection(String id) async {
    final json = await _unwrap(_dio.get('/collections/$id'));
    return CollectionDetail.fromJson(json);
  }

  Future<void> updateCollection(
    String id, {
    String? name,
    String? description,
    String? color,
  }) {
    return _unwrap(
      _dio.patch(
        '/collections/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (color != null) 'color': color,
        },
      ),
    );
  }

  Future<void> deleteCollection(String id) =>
      _unwrap(_dio.delete('/collections/$id'));

  Future<void> addItemToCollection(String collectionId, String savedUrlId) {
    return _unwrap(
      _dio.post(
        '/collections/$collectionId/items',
        data: {'savedUrlId': savedUrlId},
      ),
    );
  }

  Future<void> removeItemFromCollection(
    String collectionId,
    String savedUrlId,
  ) {
    return _unwrap(
      _dio.delete('/collections/$collectionId/items/$savedUrlId'),
    );
  }

  // ---- Ask ------------------------------------------------------------

  Future<AskResponse> askQuestion(
    String question, {
    String? answerLanguageOverride,
  }) async {
    final json = await _unwrap(
      _dio.post(
        '/ask',
        data: {
          'question': question,
          if (answerLanguageOverride != null)
            'answerLanguageOverride': answerLanguageOverride,
        },
      ),
    );
    return AskResponse.fromJson(json);
  }

  Future<List<AskThread>> listAskThreads() async {
    final json = await _unwrap(_dio.get('/ask/threads'));
    return (json['items'] as List<dynamic>)
        .map((e) => AskThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AskThreadWithMessages> getAskThread(String id) async {
    final json = await _unwrap(_dio.get('/ask/threads/$id'));
    return AskThreadWithMessages.fromJson(json);
  }

  Future<void> deleteAskThread(String id) =>
      _unwrap(_dio.delete('/ask/threads/$id'));

  Future<AskResponse> askFollowUp(
    String threadId,
    String question, {
    String? answerLanguageOverride,
  }) async {
    final json = await _unwrap(
      _dio.post(
        '/ask/threads/$threadId/messages',
        data: {
          'question': question,
          if (answerLanguageOverride != null)
            'answerLanguageOverride': answerLanguageOverride,
        },
      ),
    );
    return AskResponse.fromJson(json);
  }

  // ---- Current user / preferences -------------------------------------

  Future<UserMe> getMe() async {
    final json = await _unwrap(_dio.get('/me'));
    return UserMe.fromJson(json);
  }

  Future<UserPreferences> updatePreferences({
    InterfaceLocale? interfaceLocale,
    AnswerLanguageMode? answerLanguageMode,
    bool? notifyReadLaterDigest,
    bool? notifyWeeklyStats,
  }) async {
    final json = await _unwrap(
      _dio.patch(
        '/me',
        data: {
          if (interfaceLocale != null)
            'interfaceLocale': interfaceLocale.toJson(),
          if (answerLanguageMode != null)
            'answerLanguageMode': answerLanguageMode.toJson(),
          if (notifyReadLaterDigest != null)
            'notifyReadLaterDigest': notifyReadLaterDigest,
          if (notifyWeeklyStats != null)
            'notifyWeeklyStats': notifyWeeklyStats,
        },
      ),
    );
    return UserPreferences.fromJson(json);
  }
}
