import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTheme;

import '../../core/localization/app_strings.dart';

/// Wraps clerk_flutter's prebuilt sign-in/sign-up widget — the brief is
/// explicit that Hazy has no separate login system, so we don't hand-build
/// auth screens (docs/backend-api-contract.md §2). clerk_flutter's widgets
/// are Material-only (they key off [ClerkThemeExtension] on a Material
/// [ThemeData]), so this screen stays a self-contained Material subtree
/// rather than using Shad components.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = ShadTheme.of(context).brightness == Brightness.light;
    return Theme(
      data: (isLight ? ThemeData.light() : ThemeData.dark()).copyWith(
        extensions: [isLight ? ClerkThemeExtension.light : ClerkThemeExtension.dark],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.of(context).signInToHazy),
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
