import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/saved_url.dart';

class SavedUrlCard extends StatelessWidget {
  const SavedUrlCard({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
  });

  final SavedUrl item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 40,
        height: 40,
        child: item.faviconUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: item.faviconUrl!,
                  errorWidget: (context, url, error) => const Icon(Icons.link),
                  placeholder: (context, url) => const SizedBox.shrink(),
                ),
              )
            : const Icon(Icons.link),
      ),
      title: Text(
        item.displayTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.description != null)
            Text(
              item.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (item.domain != null)
                Flexible(
                  child: Text(
                    item.domain!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              if (item.estimatedReadMinutes != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${item.estimatedReadMinutes} min',
                  style: theme.textTheme.labelSmall,
                ),
              ],
              if (item.fetchStatus == FetchStatus.error) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: trailing,
      isThreeLine: item.description != null,
    );
  }
}
