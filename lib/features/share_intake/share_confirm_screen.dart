import 'package:flutter/material.dart' show Scaffold, AppBar, CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/localization/app_strings.dart';
import '../library/library_providers.dart';

class ShareConfirmScreen extends ConsumerStatefulWidget {
  const ShareConfirmScreen({super.key, required this.sharedUrl});

  final String sharedUrl;

  @override
  ConsumerState<ShareConfirmScreen> createState() => _ShareConfirmScreenState();
}

class _ShareConfirmScreenState extends ConsumerState<ShareConfirmScreen> {
  late final _controller = TextEditingController(text: widget.sharedUrl);
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(libraryProvider.notifier).save(_controller.text.trim());
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.saveToHazy)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.urlLabel, style: theme.textTheme.small),
            const SizedBox(height: 6),
            ShadInput(controller: _controller, keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            ShadButton(
              width: double.infinity,
              onPressed: _isSaving ? null : _save,
              leading: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }
}
