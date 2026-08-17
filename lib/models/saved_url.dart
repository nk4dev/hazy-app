enum FetchStatus {
  pending,
  success,
  error;

  static FetchStatus fromJson(String value) => FetchStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => FetchStatus.pending,
      );
}

enum ReadLaterStatus {
  inbox,
  snoozed,
  read,
  archived;

  static ReadLaterStatus? fromJson(String? value) {
    if (value == null) return null;
    return ReadLaterStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReadLaterStatus.inbox,
    );
  }

  String toJson() => name;
}

class SavedUrl {
  const SavedUrl({
    required this.id,
    required this.url,
    required this.domain,
    required this.title,
    required this.description,
    required this.faviconUrl,
    required this.ogImageUrl,
    required this.summary,
    required this.contentLanguage,
    required this.estimatedReadMinutes,
    required this.fetchStatus,
    required this.fetchError,
    required this.createdAt,
    required this.updatedAt,
    required this.readLaterStatus,
  });

  factory SavedUrl.fromJson(Map<String, dynamic> json) {
    return SavedUrl(
      id: json['id'] as String,
      url: json['url'] as String,
      domain: json['domain'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      ogImageUrl: json['ogImageUrl'] as String?,
      summary: json['summary'] as String?,
      contentLanguage: json['contentLanguage'] as String?,
      estimatedReadMinutes: (json['estimatedReadMinutes'] as num?)?.toInt(),
      fetchStatus: FetchStatus.fromJson(json['fetchStatus'] as String),
      fetchError: json['fetchError'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      readLaterStatus: ReadLaterStatus.fromJson(
        json['readLaterStatus'] as String?,
      ),
    );
  }

  final String id;
  final String url;
  final String? domain;
  final String? title;
  final String? description;
  final String? faviconUrl;
  final String? ogImageUrl;
  final String? summary;
  final String? contentLanguage;
  final int? estimatedReadMinutes;
  final FetchStatus fetchStatus;
  final String? fetchError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReadLaterStatus? readLaterStatus;

  SavedUrl copyWith({
    String? title,
    String? summary,
    FetchStatus? fetchStatus,
    String? fetchError,
    ReadLaterStatus? readLaterStatus,
  }) {
    return SavedUrl(
      id: id,
      url: url,
      domain: domain,
      title: title ?? this.title,
      description: description,
      faviconUrl: faviconUrl,
      ogImageUrl: ogImageUrl,
      summary: summary ?? this.summary,
      contentLanguage: contentLanguage,
      estimatedReadMinutes: estimatedReadMinutes,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      fetchError: fetchError ?? this.fetchError,
      createdAt: createdAt,
      updatedAt: updatedAt,
      readLaterStatus: readLaterStatus ?? this.readLaterStatus,
    );
  }

  String get displayTitle => title?.isNotEmpty == true ? title! : url;
}
