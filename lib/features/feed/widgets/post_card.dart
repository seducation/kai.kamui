import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/post_item.dart';
import '../controllers/feed_controller.dart';

/// Widget to render an organic post in the feed
class PostCard extends StatefulWidget {
  final PostItem post;
  final FeedController controller;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.controller,
    required this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  DateTime? _viewStartTime;
  bool _hasLiked = false;

  void _onVisible() {
    _viewStartTime = DateTime.now();
  }

  void _onHidden() {
    if (_viewStartTime != null) {
      final dwellTime = DateTime.now()
          .difference(_viewStartTime!)
          .inMilliseconds;

      // Track dwell or skip based on time
      if (dwellTime < 1000) {
        widget.controller.trackSkip(widget.post.postId, dwellTime);
      } else if (dwellTime > 3000) {
        widget.controller.trackDwell(widget.post.postId, dwellTime);
      }

      _viewStartTime = null;
    }
  }

  void _handleLike() {
    setState(() {
      _hasLiked = !_hasLiked;
    });
    if (_hasLiked) {
      widget.controller.trackLike(widget.post.postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post_${widget.post.postId}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          _onVisible();
        } else {
          _onHidden();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundImage: widget.post.profileImage != null
                    ? NetworkImage(widget.post.profileImage!)
                    : null,
                child: widget.post.profileImage == null
                    ? Text(
                        widget.post.username.isNotEmpty
                            ? widget.post.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(
                widget.post.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                timeago.format(widget.post.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show options menu
                },
              ),
            ),

            // Media (if present)
            if (widget.post.mediaUrls.isNotEmpty)
              GestureDetector(
                onTap: widget.onTap,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.network(
                    widget.post.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),

            // Engagement buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _hasLiked ? Icons.favorite : Icons.favorite_border,
                      color: _hasLiked ? Colors.red : null,
                    ),
                    onPressed: _handleLike,
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () {
                      widget.controller.trackComment(widget.post.postId);
                      // Navigate to comments
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () {
                      widget.controller.trackShare(widget.post.postId);
                      // Share post
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {
                      // Save post
                    },
                  ),
                ],
              ),
            ),

            // Engagement count
            if (widget.post.engagementScore > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${widget.post.engagementScore} likes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

            // Content
            if (widget.post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${widget.post.username} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: widget.post.content),
                    ],
                  ),
                ),
              ),

            // Tags
            if (widget.post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  children: widget.post.tags.map((tag) {
                    return Text(
                      '#$tag',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
