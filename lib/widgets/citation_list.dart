import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ask.dart';

/// A scrollable list of citations — deliberately not a fixed-size row of
/// chips, since the brief warns citation counts are variable and can be
/// long (docs/ai/make-flutter-app.md §6, Ask section).
class CitationList extends StatelessWidget {
  const CitationList({super.key, required this.citations});

  final List<AskCitation> citations;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sources', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ...citations.map(
          (c) => Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 12,
                child: Text('${c.rank}', style: theme.textTheme.labelSmall),
              ),
              title: Text(
                c.title?.isNotEmpty == true ? c.title! : c.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                c.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => launchUrl(
                Uri.parse(c.url),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
