import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/hmv_features_tabscreen.dart';
import 'package:my_app/model/profile.dart';
import 'package:provider/provider.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _Comment {
  final String id;
  final String text;
  final Profile? author;
  final String profileId;
  final DateTime timestamp;
  final String? parentCommentId;
  List<_Comment> replies;

  _Comment({
    required this.id,
    required this.text,
    this.author,
    required this.profileId,
    required this.timestamp,
    this.parentCommentId,
  }) : replies = [];
}

class _CommentsScreenState extends State<CommentsScreen> {
  late AppwriteService _appwriteService;
  List<_Comment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _appwriteService = context.read<AppwriteService>();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final commentsResponse =
          await _appwriteService.getComments(widget.post.id);
      final profilesResponse = await _appwriteService.getProfiles();

      final profilesMap = {
        for (var p in profilesResponse.rows) p.$id: Profile.fromMap(p.data, p.$id)
      };

      final allComments = commentsResponse.rows.map((row) {
        final profileId = row.data['profile_id'] as String;
        final author = profilesMap[profileId];

        return _Comment(
          id: row.$id,
          text: row.data['text'] as String? ?? '',
          author: author,
          profileId: profileId,
          timestamp:
              DateTime.tryParse(row.data['timestamp'] ?? '') ?? DateTime.now(),
          parentCommentId: row.data['parent_comment_id'] as String?,
        );
      }).toList();

      final commentMap = {for (var c in allComments) c.id: c};
      final nestedComments = <_Comment>[];

      for (final comment in allComments) {
        if (comment.parentCommentId != null &&
            commentMap.containsKey(comment.parentCommentId)) {
          commentMap[comment.parentCommentId]!.replies.add(comment);
        } else {
          nestedComments.add(comment);
        }
      }

      if (mounted) {
        setState(() {
          _comments = nestedComments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error
    }
  }

  Future<void> _addComment({String? parentCommentId}) async {
    if (_commentController.text.isEmpty) {
      return;
    }

    final user = await _appwriteService.getUser();
    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You must be logged in to comment.'),
      ));
      return;
    }

    final profiles = await _appwriteService.getUserProfiles(ownerId: user.$id);
    if (!mounted) return;

    final userProfiles = profiles.rows.where((p) => p.data['type'] == 'profile');

    if (userProfiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You must have a user profile to comment.'),
      ));
      return;
    }

    final profileId = userProfiles.first.$id;

    try {
      await _appwriteService.createComment(
        postId: widget.post.id,
        profileId: profileId,
        text: _commentController.text,
        parentCommentId: parentCommentId,
      );
      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
      });
      await _fetchComments(); // Refresh comments
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to add comment. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCommentsList(),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_comments.isEmpty) {
      return const Center(
        child: Text('No comments yet. Be the first to comment!'),
      );
    }

    return ListView.builder(
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        return _buildCommentItem(_comments[index]);
      },
    );
  }

  Widget _buildCommentItem(_Comment comment, {int depth = 0}) {
    final author = comment.author;
    final isValidUrl = author?.profileImageUrl != null &&
        (author!.profileImageUrl!.startsWith('http') ||
            author.profileImageUrl!.startsWith('https'));

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 8.0, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isValidUrl)
                CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(author.profileImageUrl!),
                )
              else
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author?.name ?? 'Unknown User (${comment.profileId})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(comment.text),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _replyingToCommentId = comment.id;
                        });
                      },
                      child: const Text('Reply'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ...comment.replies.map((reply) => _buildCommentItem(reply, depth: depth + 1)),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (_replyingToCommentId != null)
            Row(
              children: [
                Text('Replying to comment...'),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _replyingToCommentId = null;
                    });
                  },
                )
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId == null
                        ? 'Add a comment...'
                        : 'Add a reply...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _addComment(parentCommentId: _replyingToCommentId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
