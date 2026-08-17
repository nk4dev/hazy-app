import 'dart:async';

import 'package:flutter/material.dart' show Scaffold, AppBar, ListView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../models/saved_url.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/saved_url_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  AsyncValue<List<SavedUrl>> _result = const AsyncValue.data([]);

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    if (value.trim().isEmpty) {
      setState(() => _result = const AsyncValue.data([]));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _result = const AsyncValue.loading());
    try {
      final api = ref.read(apiClientProvider);
      final items = await api.search(query);
      if (!mounted) return;
      setState(() => _result = AsyncValue.data(items));
    } on ApiException catch (e, st) {
      if (!mounted) return;
      setState(() => _result = AsyncValue.error(e, st));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: ShadInput(
          controller: _controller,
          autofocus: false,
          onChanged: _onChanged,
          leading: const Icon(LucideIcons.search, size: 18),
          placeholder: Text(s.searchPlaceholder),
        ),
      ),
      body: switch (_result) {
        AsyncData(:final value) => _query.trim().isEmpty
            ? EmptyState(
                icon: LucideIcons.search,
                title: s.searchLibraryTitle,
                subtitle: s.searchLibrarySubtitle,
              )
            : value.isEmpty
                ? EmptyState(icon: LucideIcons.searchX, title: s.noResults)
                : ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final item = value[index];
                      return SavedUrlCard(
                        item: item,
                        onTap: () => context.push('/library/item/${item.id}'),
                      );
                    },
                  ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => _search(_query.trim()),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
