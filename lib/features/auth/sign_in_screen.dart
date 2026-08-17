import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

/// Wraps clerk_flutter's prebuilt sign-in/sign-up widget — the brief is
/// explicit that Hazy has no separate login system, so we don't hand-build
/// auth screens (docs/ai/make-flutter-app.md §2).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Theme(
      data: (isLight ? ThemeData.light() : ThemeData.dark()).copyWith(
        extensions: [isLight ? ClerkThemeExtension.light : ClerkThemeExtension.dark],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign in to Hazy'),
          automaticallyImplyLeading: false,
        ),
        body: const SafeArea(
          child: ClerkErrorListener(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ClerkAuthentication(),
            ),
          ),
        ),
      ),
    );
  }
}
