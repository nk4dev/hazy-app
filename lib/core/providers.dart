import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/clerk_token_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(getToken: ClerkAuthBridge.getToken);
});
