import 'feed_item.dart';

/// Represents a sponsored ad in the feed
class AdItem extends FeedItem {
  final String adId;
  final String advertiserId;
  final String content;
  final String mediaUrl;
  final String? linkUrl;
  final List<String> targetTags;
  final double eCPM;

  AdItem({
    required this.adId,
    required this.advertiserId,
    required this.content,
    required this.mediaUrl,
    this.linkUrl,
    required this.targetTags,
    required this.eCPM,
  }) : super(id: adId, type: 'ad');

  /// Create from JSON
  factory AdItem.fromJson(Map<String, dynamic> json) {
    return AdItem(
      adId: json['adId'] ?? json['\$id'] ?? '',
      advertiserId: json['advertiserId'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      linkUrl: json['linkUrl'],
      targetTags: (json['targetTags'] as List<dynamic>?)?.cast<String>() ?? [],
      eCPM: (json['eCPM'] ?? 0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'adId': adId,
      'advertiserId': advertiserId,
      'content': content,
      'mediaUrl': mediaUrl,
      'linkUrl': linkUrl,
      'targetTags': targetTags,
      'eCPM': eCPM,
    };
  }
}
