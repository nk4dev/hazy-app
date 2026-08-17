# Hazy mobile — agent guide

This is the Flutter client for **Hazy** ("a memory for the URLs you save").
It is a client only: all data, AI, and business logic live in Hazy's
existing Next.js backend at `/api/v1/**`. This repo must never invent
endpoints, reshape response payloads, or duplicate backend logic — it
consumes the contract documented in
[`docs/backend-api-contract.md`](docs/backend-api-contract.md) (a copy of
the brief this app was built from; keep it in sync if the backend contract
changes) as-is.

Read that file before changing any networking or data-model code — it's
the source of truth for every endpoint, DTO shape, and error code.

## Current status

Builds, installs, and runs on a real Android emulator against the real
deployed backend (`flutter analyze` clean, `flutter test` passing). A
`.env.local` with a real Clerk publishable key and the deployed API base
URL (`https://hazy.n-knight-pc0627.workers.dev/api/v1`) exists locally
(gitignored, not committed — see `.env.example` for the template).
Confirmed end-to-end so far:
- `GET /me` unauthenticated returns
  `{"error":{"code":"unauthorized","message":"Sign in required."}}`,
  matching `ApiClient`'s expected envelope exactly.
- `flutter run -d <android-emulator> --dart-define-from-file=.env.local`
  builds, installs, and launches on Android; the Clerk sign-in screen
  (`ClerkAuthentication()`) renders correctly with GitHub/Google OAuth
  buttons — confirms `ConfigGate` → `ClerkAuth` → go_router `/sign-in`
  wiring all works against real credentials.

Not yet done: actually signing in and walking the post-auth screens
(library, ask, etc) against the real backend — verified up to the sign-in
screen only so far. Whoever picks this up next should sign in and exercise
each feature.

## Running

```bash
flutter run --dart-define-from-file=.env.local
```

(`.env.local` already has real values — see above. `.gitignore` excludes
every `.env*` file except `.env.example`.) Or, without a local env file:

```bash
flutter run \
  --dart-define=HAZY_API_BASE_URL=https://your-host/api/v1 \
  --dart-define=CLERK_PUBLISHABLE_KEY=pk_...
```

Without both defines, the app shows a "not configured" screen instead of
touching the Clerk SDK (`lib/features/auth/config_gate_screen.dart`) —
this is intentional, not a bug, so the app never crashes on a missing key.

For the Android emulator against a local `next dev` server, the default
`HAZY_API_BASE_URL` (`http://10.0.2.2:3000/api/v1`) already points at the
host machine's loopback — you only need to supply the Clerk key in that
case.

## Architecture

```
lib/
  main.dart                 # ClerkAuth + ProviderScope + MaterialApp.router wiring
  core/
    config/app_config.dart  # --dart-define values, isConfigured gate
    api/                    # ApiClient (Dio) + ApiException — the only place that talks HTTP
    auth/                   # ClerkAuthBridge: bridges ClerkAuthState (needs BuildContext)
                             # into plain callbacks for ApiClient and go_router
    router/                 # go_router config + bottom-nav shell
    providers.dart          # apiClientProvider
  models/                   # Plain Dart DTOs, 1:1 with docs/backend-api-contract.md §5
  features/                 # One directory per screen area (see below), each with its
                             # own Riverpod providers file + screen widget(s)
  widgets/                  # Shared presentational widgets (cards, empty/error/loading states)
```

Features, matching the backend brief's suggested build order: `auth`,
`library`, `item_detail`, `read_later`, `search`, `collections`, `ask`,
`settings`, `share_intake`.

## Key decisions (and why)

- **No code generation.** `freezed`, `json_serializable`, and
  `riverpod_generator` all conflict with the `riverpod`/`freezed_annotation`
  versions that resolve on this Flutter/Dart SDK (Flutter 3.32, Dart 3.8) —
  see the version-solving failures if you try to add them back. Models are
  plain classes with hand-written `fromJson`, state is plain
  `flutter_riverpod` (`AsyncNotifier`, `Provider`, `.family(...)`). If you
  upgrade the Flutter SDK and want codegen back, re-check this — it may no
  longer conflict.
- **Riverpod 3 API note**: `AsyncValue.valueOrNull` was renamed to
  `AsyncValue.value` (nullable) in riverpod 3.x. `AsyncNotifierProvider.family`
  takes `(NotifierT Function(ArgT arg))` — the arg is passed to the
  notifier's constructor, not read from a `ref`/`arg` property.
- **Android build config**: `android/app/build.gradle.kts` pins
  `ndkVersion = "27.0.12077973"` and `minSdk = maxOf(flutter.minSdkVersion, 23)`
  — several transitive plugin deps pulled in by `clerk_flutter` require
  this (highest floor is `passkeys_android`, used for WebAuthn/passkey
  sign-in, at minSdk 23; NDK 27 is needed by `device_info_plus`,
  `receive_sharing_intent`, etc). If a future `flutter pub upgrade` adds a
  plugin demanding more, grep
  `build/*/intermediates/merged_manifest/**/AndroidManifest.xml` for
  `minSdkVersion` after a failed build to find the new floor, rather than
  bumping one at a time off each error message.
- **Android JVM target mismatch**: several plugin subprojects (e.g.
  `receive_sharing_intent`, `device_info_plus`) don't pin a Kotlin
  `jvmTarget` matching their own Java `sourceCompatibility`, which Gradle
  rejects as "Inconsistent JVM-target compatibility". Fixed in
  `android/build.gradle.kts` by forcing every non-`app` subproject's
  `JavaCompile`/`KotlinCompile` tasks to the same target (17) inside a
  **doubly-nested** `afterEvaluate` — a single `afterEvaluate` isn't enough
  because AGP registers its own `afterEvaluate` (when the android plugin
  applies, during that subproject's evaluation) that finalizes
  `sourceCompatibility` *after* one registered from the root project, so it
  silently overwrites a single-level override. Reading AGP's
  `compileOptions.sourceCompatibility` back to "match" it instead of
  forcing a fixed value throws `"sourceCompatibility is not yet
  finalized"` — don't try that, it's a lazy `Property` not safe to read
  during configuration. If this breaks again after an SDK/plugin upgrade,
  re-check whether AGP's finalization order changed rather than adding a
  third nesting level blindly.
- **Auth**: `clerk_flutter`'s prebuilt `ClerkAuthentication()` widget
  handles sign-in/sign-up — do not hand-build auth forms. `ClerkAuthState`
  (from `ClerkAuth.of(context)`) is a `ChangeNotifier`
  (`ClerkAuthState extends clerk.Auth with ChangeNotifier`), so
  `lib/core/auth/clerk_token_provider.dart`'s `ClerkAuthBridge` uses it
  directly as go_router's `refreshListenable` for auth redirects, and pulls
  `.sessionToken()` (`Future<SessionToken>`, `.jwt` is the string) for the
  `Authorization: Bearer` header on every API call.
- **Error handling contract**: every `/api/v1/**` response is `{ data }` or
  `{ error: { code, message, details } }` — `ApiClient` always branches on
  that envelope, never on HTTP status alone, and throws `ApiException`
  (see `lib/core/api/api_exception.dart`) so UI code never touches
  `DioException` directly.
- **Android-only share sheet for now.** `lib/features/share_intake` +
  the `AndroidManifest.xml` `SEND`/`text/plain` intent-filter let other
  apps share a URL into Hazy's save flow. No iOS Share Extension yet — that
  needs native Xcode target setup that wasn't done (and can't easily be
  verified without a Mac); add it later without needing to touch
  `share_intake`'s Dart code.

## Known gaps (carried over from the backend brief, don't build around them)

- No push notification infrastructure server-side yet. The
  `notifyReadLaterDigest`/`notifyWeeklyStats` toggles in Settings persist
  via `PATCH /me` but nothing sends anything — don't add FCM/APNs wiring
  without checking with the project owner first.
- `fetchStatus: "pending"` is a rare edge case (mid-request from elsewhere)
  — `POST /items` already returns the final `success`/`error` status
  synchronously, there's no polling needed.
- No iOS Share Extension (see above).

## Verification

- `flutter analyze` should stay clean.
- `flutter test` runs a smoke test that boots `HazyApp` unconfigured and
  checks the config-gate screen renders — keep this passing as the cheapest
  signal that the widget tree/router/Riverpod setup still wires together.
- There is no automated verification against a *real* backend yet — that
  requires the Clerk key + API URL mentioned above.
