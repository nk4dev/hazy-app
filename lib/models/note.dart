/// DTOs for hazy note (`apps/hazy-note` in the hazy repo), mirroring
/// `lib/types.ts` there. Unlike the `/v1` models these come from hazy note's
/// own `/api/*` routes — see `lib/core/api/note_api_client.dart`.
library;

enum NoteStatus {
  draft,
  done;

  static NoteStatus fromJson(Object? value) =>
      value == 'done' ? NoteStatus.done : NoteStatus.draft;
}

class NoteTag {
  const NoteTag({required this.label, this.tone = 'neutral'});

  factory NoteTag.fromJson(Map<String, dynamic> json) => NoteTag(
        label: json['label'] as String? ?? '',
        tone: json['tone'] as String? ?? 'neutral',
      );

  final String label;

  /// `"accent" | "neutral" | "outline"`.
  final String tone;

  Map<String, dynamic> toJson() => {'label': label, 'tone': tone};
}

/// An AI-drafted suggestion the user can take into the body or dismiss.
class NoteSuggestion {
  const NoteSuggestion({
    required this.id,
    required this.kind,
    required this.text,
    this.ref,
  });

  factory NoteSuggestion.fromJson(Map<String, dynamic> json) => NoteSuggestion(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        text: json['text'] as String? ?? '',
        ref: json['ref'] as String?,
      );

  final String id;
  final String kind;
  final String text;
  final String? ref;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'text': text,
        if (ref != null) 'ref': ref,
      };
}

/// A source the note cites (added when a saved URL is `@`-mentioned).
class NoteSourceRef {
  const NoteSourceRef({
    required this.n,
    required this.label,
    required this.cited,
    this.url,
  });

  factory NoteSourceRef.fromJson(Map<String, dynamic> json) => NoteSourceRef(
        n: (json['n'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        cited: json['cited'] as bool? ?? false,
        url: json['url'] as String?,
      );

  final int n;
  final String label;
  final bool cited;
  final String? url;

  Map<String, dynamic> toJson() => {
        'n': n,
        'label': label,
        'cited': cited,
        if (url != null) 'url': url,
      };
}

class NoteFlag {
  const NoteFlag({required this.tone, required this.text});

  factory NoteFlag.fromJson(Map<String, dynamic> json) => NoteFlag(
        tone: json['tone'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  final String tone;
  final String text;
}

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.projectId,
    required this.tags,
    required this.status,
    required this.updatedLabel,
    required this.body,
    required this.suggestions,
    required this.sources,
    required this.flags,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      tags: maps('tags').map(NoteTag.fromJson).toList(),
      status: NoteStatus.fromJson(json['status']),
      updatedLabel: json['updatedLabel'] as String? ?? '',
      body: maps('body'),
      suggestions: maps('suggestions').map(NoteSuggestion.fromJson).toList(),
      sources: maps('sources').map(NoteSourceRef.fromJson).toList(),
      flags: maps('flags').map(NoteFlag.fromJson).toList(),
    );
  }

  final String id;
  final String title;

  /// `""` when the note isn't filed under a project.
  final String projectId;
  final List<NoteTag> tags;
  final NoteStatus status;

  /// Server-rendered, e.g. `自動保存 · 3分前`.
  final String updatedLabel;

  /// The body as Quill Delta ops (`[{insert, attributes?}, ...]`).
  final List<Map<String, dynamic>> body;
  final List<NoteSuggestion> suggestions;
  final List<NoteSourceRef> sources;
  final List<NoteFlag> flags;

  /// Plain-text preview of the body for list rows.
  String get preview {
    final buffer = StringBuffer();
    for (final op in body) {
      final insert = op['insert'];
      if (insert is String) buffer.write(insert);
      if (buffer.length > 240) break;
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// A hazy note project (distinct from Hazy's collections).
class NoteProject {
  const NoteProject({required this.id, required this.name});

  factory NoteProject.fromJson(Map<String, dynamic> json) => NoteProject(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
      );

  final String id;
  final String name;
}
