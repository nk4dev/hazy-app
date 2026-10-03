import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'api/note_api_client.dart';
import 'auth/clerk_token_provider.dart';
import 'db/local_database.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(getToken: ClerkAuthBridge.getToken);
});

final noteApiClientProvider = Provider<NoteApiClient>((ref) {
  return NoteApiClient(getToken: ClerkAuthBridge.getToken);
});
