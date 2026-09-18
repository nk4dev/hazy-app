import 'saved_url.dart';

class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.summary,
    required this.summaryUpdatedAt,
    required this.itemCount,
    required this.previewImages,
    required this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      summary: json['summary'] as String?,
      summaryUpdatedAt: json['summaryUpdatedAt'] != null
          ? DateTime.parse(json['summaryUpdatedAt'] as String)
          : null,
      itemCount: (json['itemCount'] as num).toInt(),
      previewImages: (json['previewImages'] as List<dynamic>? ?? const [])
          .cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? summary;
  final DateTime? summaryUpdatedAt;
  final int itemCount;
  final List<String> previewImages;
  final DateTime createdAt;
}

/// `GET /collections/:id` response — a collection plus its items.
class CollectionDetail {
  const CollectionDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.summary,
    required this.summaryUpdatedAt,
    required this.items,
  });

  factory CollectionDetail.fromJson(Map<String, dynamic> json) {
    return CollectionDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      summary: json['summary'] as String?,
      summaryUpdatedAt: json['summaryUpdatedAt'] != null
          ? DateTime.parse(json['summaryUpdatedAt'] as String)
          : null,
      items: (json['items'] as List<dynamic>)
          .map((e) => SavedUrl.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? summary;
  final DateTime? summaryUpdatedAt;
  final List<SavedUrl> items;
}

/// `POST /collections/:id/summarize` response.
class CollectionSummary {
  const CollectionSummary({required this.summary, required this.summaryUpdatedAt});

  factory CollectionSummary.fromJson(Map<String, dynamic> json) {
    return CollectionSummary(
      summary: json['summary'] as String,
      summaryUpdatedAt: DateTime.parse(json['summaryUpdatedAt'] as String),
    );
  }

  final String summary;
  final DateTime summaryUpdatedAt;
}
