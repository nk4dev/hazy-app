import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_strings.dart';
import '../models/ask.dart';

/// A scrollable list of citations — deliberately not a fixed-size row of
/// chips, since the brief warns citation counts are variable and can be
/// long (docs/backend-api-contract.md §6, Ask section).
class CitationList extends StatelessWidget {
  const CitationList({super.key, required this.citations});

  final List<AskCitation> citations;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.sources, style: theme.textTheme.small),
        const SizedBox(height: 4),
        ...citations.map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(c.url),
                mode: LaunchMode.externalApplication,
              ),
              child: ShadCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShadBadge(child: Text('${c.rank}')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.title?.isNotEmpty == true ? c.title! : c.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.small,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
