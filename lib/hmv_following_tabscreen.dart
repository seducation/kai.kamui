import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/model/post.dart';
import 'package:provider/provider.dart';
import './widgets/post_item.dart';
import 'model/profile.dart';

class HMVFollowingTabscreen extends StatefulWidget {
  const HMVFollowingTabscreen({super.key});

  @override
  State<HMVFollowingTabscreen> createState() => _HMVFollowingTabscreenState();
}

class _HMVFollowingTabscreenState extends State<HMVFollowingTabscreen> {
  late AppwriteService appwriteService;
  late AuthService authService;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    appwriteService = context.read<AppwriteService>();
    authService = context.read<AuthService>();
    _fetchFollowingPosts();
  }

  Future<void> _fetchFollowingPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final profileResponse =
          await appwriteService.getUserProfiles(ownerId: user.id);
      if (profileResponse.rows.isEmpty) {
        throw Exception('Profile not found');
      }
      final profileData = profileResponse.rows.first.data;

      final followingIds = List<String>.from(profileData['following'] ?? []);

      if (followingIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        appwriteService.getPostsFromUsers(followingIds),
        appwriteService.getProfiles(),
      ]);

      final postsResponse = results[0];
      final profilesResponse = results[1];

      final profilesMap = {
        for (var doc in profilesResponse.rows) doc.$id: doc.data
      };

      final posts = postsResponse.rows.map((row) {
        final profileIds = row.data['profile_id'] as List?;
        final profileId = (profileIds?.isNotEmpty ?? false)
            ? profileIds!.first as String?
            : null;
        if (profileId == null) return null;

        final creatorProfileData = profilesMap[profileId];
        if (creatorProfileData == null) return null;

        final author = Profile.fromMap(creatorProfileData, profileId);

        final updatedAuthor = Profile(
          id: author.id,
          name: author.name,
          type: author.type,
          bio: author.bio,
          profileImageUrl: author.profileImageUrl != null &&
                  author.profileImageUrl!.isNotEmpty
              ? appwriteService.getFileViewUrl(author.profileImageUrl!)
              : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
          ownerId: author.ownerId,
          createdAt: author.createdAt,
        );

        final fileIdsData = row.data['file_ids'];
        final List<String> fileIds = fileIdsData is List
            ? List<String>.from(fileIdsData.map((id) => id.toString()))
            : [];

        String? postTypeString = row.data['type'];
        if (postTypeString == null && fileIds.isNotEmpty) {
          postTypeString = 'image'; // Infer type for old data
        }

        final postType = _getPostType(postTypeString, row.data['linkUrl']);

        String? mediaUrl;
        if (fileIds.isNotEmpty) {
          mediaUrl = appwriteService.getFileViewUrl(fileIds.first);
        }

        final postStats = PostStats(
          likes: row.data['likes'] ?? 0,
          comments: row.data['comments'] ?? 0,
          shares: row.data['shares'] ?? 0,
          views: row.data['views'] ?? 0,
        );

        final originalAuthorIds = row.data['author_id'] as List?;
        final originalAuthorId = (originalAuthorIds?.isNotEmpty ?? false)
            ? originalAuthorIds!.first as String?
            : null;

        Profile? originalAuthor;
        if (originalAuthorId != null && originalAuthorId != profileId) {
          final originalAuthorProfileData = profilesMap[originalAuthorId];
          if (originalAuthorProfileData != null) {
            originalAuthor =
                Profile.fromMap(originalAuthorProfileData, originalAuthorId);
          }
        }

        return Post(
          id: row.$id,
          author: updatedAuthor,
          originalAuthor: originalAuthor,
          timestamp:
              DateTime.tryParse(row.data['timestamp'] ?? '') ?? DateTime.now(),
          contentText: row.data['caption'] ?? '',
          mediaUrl: mediaUrl,
          type: postType,
          stats: postStats,
          linkUrl: row.data['linkUrl'],
          linkTitle: row.data['titles'],
          authorIds: (row.data['author_id'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
          profileIds: (row.data['profile_id'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
        );
      }).where((post) => post != null).cast<Post>().toList();

      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  PostType _getPostType(String? type, String? linkUrl) {
    if (linkUrl != null && linkUrl.isNotEmpty) {
      return PostType.linkPreview;
    }
    switch (type) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      default:
        return PostType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_error', textAlign: TextAlign.center),
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child:
            Text('No posts yet. Follow some people to see their posts here.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFollowingPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return PostItem(post: post, profileId: authService.currentUser!.id);
        },
      ),
    );
  }
}
