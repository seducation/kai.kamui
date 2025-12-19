import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/model/post.dart';
import 'package:provider/provider.dart';

import 'hmv_features_tabscreen.dart';
import 'model/profile.dart';

class HMVShortsTabscreen extends StatefulWidget {
  const HMVShortsTabscreen({super.key});

  @override
  State<HMVShortsTabscreen> createState() => _HMVShortsTabscreenState();
}

class _HMVShortsTabscreenState extends State<HMVShortsTabscreen> {
  late AppwriteService appwriteService;
  List<Post>? _posts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    appwriteService = context.read<AppwriteService>();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final postsResponse = await appwriteService.getPosts();
      final profilesResponse = await appwriteService.getProfiles();

      final profilesMap = {for (var p in profilesResponse.rows) p.$id: Profile.fromMap(p.data, p.$id)};

      final posts = postsResponse.rows.map((row) {
        final profileId = row.data['profile_id'] as String?;
        final author = profilesMap[profileId];

        if (author == null) {
          return null;
        }

        PostType type = PostType.text;
        String? mediaUrl;
        final fileIds = row.data['file_ids'] as List?;
        if (fileIds != null && fileIds.isNotEmpty) {
          type = PostType.image;
          mediaUrl = appwriteService.getFileViewUrl(fileIds.first);
        }

        return Post(
          id: row.$id,
          author: author,
          timestamp: DateTime.tryParse(row.data['timestamp'] ?? '') ?? DateTime.now(),
          linkTitle: row.data['titles'] as String? ?? '',
          contentText: row.data['caption'] as String? ?? '',
          type: type,
          mediaUrl: mediaUrl,
          linkUrl: row.data['linkUrl'] as String?,
          stats: PostStats(
            likes: row.data['likes'] ?? 0,
            comments: row.data['comments'] ?? 0,
            shares: row.data['shares'] ?? 0,
            views: row.data['views'] ?? 0,
          ),
        );
      }).whereType<Post>().toList();

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_posts == null || _posts!.isEmpty) {
      return const Center(
        child: Text("No posts available."),
      );
    }

    return ListView.separated(
      itemCount: _posts!.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final post = _posts![index];
        return PostWidget(post: post, allPosts: _posts!);
      },
    );
  }
}