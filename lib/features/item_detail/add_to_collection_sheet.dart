import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../collections/collections_providers.dart';

Future<void> showAddToCollectionSheet(
  BuildContext context,
  WidgetRef ref,
  String savedUrlId,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final collectionsAsync = ref.watch(collectionsProvider);
      return SafeArea(
        child: switch (collectionsAsync) {
          AsyncData(:final value) => value.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No collections yet. Create one from the Library tab.'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final collection in value)
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(collection.name),
                        subtitle: Text('${collection.itemCount} items'),
                        onTap: () async {
                          final api = ref.read(apiClientProvider);
                          await api.addItemToCollection(collection.id, savedUrlId);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added to ${collection.name}')),
                            );
                          }
                        },
                      ),
                  ],
                ),
          AsyncError() => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load collections.'),
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
