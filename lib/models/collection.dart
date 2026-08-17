import 'saved_url.dart';

class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.itemCount,
    required this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      itemCount: (json['itemCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? color;
  final int itemCount;
  final DateTime createdAt;
}

/// `GET /collections/:id` response — a collection plus its items.
class CollectionDetail {
  const CollectionDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.items,
  });

  factory CollectionDetail.fromJson(Map<String, dynamic> json) {
    return CollectionDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => SavedUrl.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? color;
  final List<SavedUrl> items;
}
