import 'package:my_app/model/profile.dart';

enum PostType { text, image, linkPreview, video, file, audio }

class PostStats {
  int likes;
  int comments;
  final int shares;
  final int views;

  PostStats({this.likes = 0, this.comments = 0, this.shares = 0, this.views = 0});
}

class Post {
  final String id;
  final Profile author;
  final Profile? originalAuthor;
  final DateTime timestamp;
  final String contentText;
  final PostType type;
  final List<String>? mediaUrls; // Changed from mediaUrl to mediaUrls
  final String? linkUrl;
  final String? linkTitle;
  final PostStats stats;
  final List<String>? authorIds;
  final List<String>? profileIds;
  double score;
  bool isLiked;
  bool isSaved;

  Post({
    required this.id,
    required this.author,
    this.originalAuthor,
    required this.timestamp,
    required this.contentText,
    this.type = PostType.text,
    this.mediaUrls, // Changed from mediaUrl to mediaUrls
    this.linkUrl,
    this.linkTitle,
    required this.stats,
    this.authorIds,
    this.profileIds,
    this.score = 0.0,
    this.isLiked = false,
    this.isSaved = false,
  });
}
