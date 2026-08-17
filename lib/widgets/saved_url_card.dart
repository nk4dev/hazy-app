import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' show ListTile;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/saved_url.dart';

/// No direct shadcn_ui equivalent for a tappable list row with
/// leading/trailing slots (it only ships value-picker/menu components), so
/// this stays a Material [ListTile] — but themed and iconified consistently
/// with the rest of the shadcn_ui-based UI.
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
    final theme = ShadTheme.of(context);
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
                  errorWidget: (context, url, error) =>
                      const Icon(LucideIcons.link),
                  placeholder: (context, url) => const SizedBox.shrink(),
                ),
              )
            : const Icon(LucideIcons.link),
      ),
      title: Text(
        item.displayTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.p,
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
              style: theme.textTheme.muted,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (item.domain != null)
                Flexible(
                  child: Text(
                    item.domain!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small,
                  ),
                ),
              if (item.estimatedReadMinutes != null) ...[
                const SizedBox(width: 6),
                Text('· ${item.estimatedReadMinutes} min', style: theme.textTheme.small),
              ],
              if (item.fetchStatus == FetchStatus.error) ...[
                const SizedBox(width: 6),
                Icon(
                  LucideIcons.circleAlert,
                  size: 14,
                  color: theme.colorScheme.destructive,
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
