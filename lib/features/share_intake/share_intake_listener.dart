import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/router/app_router.dart';

/// Catches URLs shared into Hazy from the Android share sheet (see
/// AndroidManifest's `SEND`/`text/plain` intent-filter) and routes to the
/// save-confirmation screen. No-op on platforms other than Android (no iOS
/// Share Extension yet, and no native implementation on web/desktop).
class ShareIntakeListener extends StatefulWidget {
  const ShareIntakeListener({super.key, required this.child});

  final Widget child;

  @override
  State<ShareIntakeListener> createState() => _ShareIntakeListenerState();
}

class _ShareIntakeListenerState extends State<ShareIntakeListener> {
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;

    ReceiveSharingIntent.instance.getInitialMedia().then(_handle);
    _subscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(_handle);
  }

  void _handle(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final candidate = files.first.path;
    final uri = Uri.tryParse(candidate.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return;
    ReceiveSharingIntent.instance.reset();
    appRouter.push('/share-confirm', extra: candidate.trim());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
