import 'post_item.dart';
import 'ad_item.dart';
import 'carousel_item.dart';

/// Base abstract class for all feed items
/// Supports: posts, ads, and carousels
abstract class FeedItem {
  final String id;
  final String type; // 'post', 'ad', 'carousel'

  FeedItem({required this.id, required this.type});

  /// Factory constructor to create appropriate FeedItem from JSON
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'post':
        return PostItem.fromJson(json);
      case 'ad':
        return AdItem.fromJson(json);
      case 'carousel':
        return CarouselItem.fromJson(json);
      default:
        throw Exception('Unknown feed item type: $type');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson();
}
