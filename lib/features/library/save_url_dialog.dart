import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/localization/app_strings.dart';
import 'library_providers.dart';

bool _isValidUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.hasScheme && uri.hasAuthority;
}

Future<void> showSaveUrlDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();

  await showShadDialog<void>(
    context: context,
    builder: (dialogContext) {
      var isSaving = false;
      String? errorText;
      return StatefulBuilder(
        builder: (context, setState) {
          final s = AppStrings.of(context);
          final fieldColumn = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShadInput(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  placeholder: const Text('https://example.com/article'),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorText!,
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: ShadTheme.of(context).colorScheme.destructive,
                        ),
                  ),
                ],
              ],
            ),
          );
          return ShadDialog(
            title: Text(s.saveALink),
            actions: [
              ShadButton.outline(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(s.cancel),
              ),
              ShadButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final url = controller.text.trim();
                        if (!_isValidUrl(url)) {
                          setState(() => errorText = s.enterValidUrl);
                          return;
                        }
                        setState(() {
                          errorText = null;
                          isSaving = true;
                        });
                        try {
                          await ref.read(libraryProvider.notifier).save(url);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } on ApiException catch (e) {
                          setState(() => isSaving = false);
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                description: Text(e.message),
                              ),
                            );
                          }
                        }
                      },
                leading: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                child: Text(s.save),
              ),
            ],
            child: fieldColumn,
          );
        },
      );
    },
  );
}
