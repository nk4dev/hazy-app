import 'package:flutter/material.dart'
    show ListTile, ListView, CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../collections/collections_providers.dart';

Future<void> showAddToCollectionSheet(
  BuildContext context,
  WidgetRef ref,
  String savedUrlId,
) async {
  await showShadSheet<void>(
    context: context,
    builder: (context) {
      final collectionsAsync = ref.watch(collectionsProvider);
      final s = AppStrings.of(context);
      return ShadSheet(
        title: Text(s.addToCollectionTitle),
        child: switch (collectionsAsync) {
          AsyncData(:final value) => value.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.noCollectionsYetShort),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final collection in value)
                      ListTile(
                        leading: const Icon(LucideIcons.folder),
                        title: Text(collection.name),
                        subtitle: Text(s.itemsCount(collection.itemCount)),
                        onTap: () async {
                          final api = ref.read(apiClientProvider);
                          await api.addItemToCollection(collection.id, savedUrlId);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ShadToaster.of(context).show(
                              ShadToast(
                                description: Text(s.addedTo(collection.name)),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
          AsyncError() => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(s.couldNotLoadCollections),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
      );
    },
  );
}
