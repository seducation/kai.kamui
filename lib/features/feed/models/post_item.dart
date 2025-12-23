import 'feed_item.dart';

/// Represents an organic post in the feed
class PostItem extends FeedItem {
  final String postId;
  final String userId;
  final String username;
  final String? profileImage;
  final String content;
  final List<String> mediaUrls;
  final List<String> tags;
  final int engagementScore;
  final int viewCount;
  final DateTime createdAt;
  final String sourcePool; // 'followed', 'interest', 'trending', etc.

  PostItem({
    required this.postId,
    required this.userId,
    required this.username,
    this.profileImage,
    required this.content,
    required this.mediaUrls,
    required this.tags,
    required this.engagementScore,
    required this.viewCount,
    required this.createdAt,
    required this.sourcePool,
  }) : super(id: postId, type: 'post');

  /// Create from JSON
  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      postId: json['postId'] ?? json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown',
      profileImage: json['profileImage'],
      content: json['content'] ?? '',
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      engagementScore: json['engagementScore'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sourcePool: json['sourcePool'] ?? 'unknown',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'postId': postId,
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'tags': tags,
      'engagementScore': engagementScore,
      'viewCount': viewCount,
      'createdAt': createdAt.toIso8601String(),
      'sourcePool': sourcePool,
    };
  }
}
