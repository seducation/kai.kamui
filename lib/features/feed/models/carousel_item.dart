import 'feed_item.dart';

/// Represents a single item within a carousel
class CarouselItemData {
  final String id;
  final String title;
  final String imageUrl;
  final String? subtitle;
  final Map<String, dynamic>? metadata;

  CarouselItemData({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.metadata,
  });

  factory CarouselItemData.fromJson(Map<String, dynamic> json) {
    return CarouselItemData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      subtitle: json['subtitle'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'subtitle': subtitle,
      'metadata': metadata,
    };
  }
}

/// Represents a carousel widget in the feed
class CarouselItem extends FeedItem {
  final String
  carouselType; // 'trending_creators', 'suggested_communities', etc.
  final String title;
  final List<CarouselItemData> items;

  CarouselItem({
    required super.id,
    required this.carouselType,
    required this.title,
    required this.items,
  }) : super(type: 'carousel');

  /// Create from JSON
  factory CarouselItem.fromJson(Map<String, dynamic> json) {
    final itemsList =
        (json['items'] as List<dynamic>?)
            ?.map((e) => CarouselItemData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CarouselItem(
      id:
          json['carouselType'] ??
          'carousel_${DateTime.now().millisecondsSinceEpoch}',
      carouselType: json['carouselType'] ?? '',
      title: json['title'] ?? 'Discover',
      items: itemsList,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'carouselType': carouselType,
      'title': title,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
