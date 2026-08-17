import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hazy_mobile/main.dart';

void main() {
  testWidgets('shows the config gate when unconfigured', (tester) async {
    // No CLERK_PUBLISHABLE_KEY is passed via --dart-define in tests, so the
    // app should show the config gate instead of touching the Clerk SDK.
    await tester.pumpWidget(const ProviderScope(child: HazyApp()));
    await tester.pump();

    expect(find.text('Hazy isn\'t configured yet'), findsOneWidget);
  });
}
