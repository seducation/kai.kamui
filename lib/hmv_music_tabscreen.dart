import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'package:provider/provider.dart';

import 'package:my_app/model/post.dart' as model;
import 'package:my_app/model/profile.dart' as profile_model;
import 'widgets/post_item.dart';

// Feed imports
import 'features/feed/controllers/feed_controller.dart';
import 'features/feed/models/feed_item.dart' as feed_models;
import 'features/feed/models/post_item.dart' as feed_models;

class HmvMusicTabscreen extends StatefulWidget {
  const HmvMusicTabscreen({super.key});

  @override
  State<HmvMusicTabscreen> createState() => _HmvMusicTabscreenState();
}

class _HmvMusicTabscreenState extends State<HmvMusicTabscreen>
    with AutomaticKeepAliveClientMixin {
  late FeedController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final appwriteService = context.read<AppwriteService>();
    final authService = context.read<AuthService>();

    _controller = FeedController(
      client: appwriteService.client,
      userId: authService.currentUser?.id ?? '',
      postType: 'audio',
    );

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _controller.loadFeed();
    }
  }

  model.Post? _convertToModelPost(feed_models.FeedItem item) {
    if (item is! feed_models.PostItem) return null;

    model.PostType type = model.PostType.audio;

    return model.Post(
      id: item.postId,
      author: profile_model.Profile(
        id: item.userId,
        name: item.username,
        type: 'profile',
        profileImageUrl: item.profileImage,
        ownerId: '',
        createdAt: DateTime.now(),
      ),
      timestamp: item.createdAt,
      contentText: item.content,
      type: type,
      mediaUrls: item.mediaUrls,
      stats: model.PostStats(
        likes: item.engagementScore,
        views: item.viewCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Consumer<FeedController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.feedItems.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.feedItems.isEmpty) {
              if (controller.error != null) {
                return Center(child: Text('Error: ${controller.error}'));
              }
              return const Center(child: Text("No music available."));
            }

            return RefreshIndicator(
              onRefresh: () => controller.refresh(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: controller.feedItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.feedItems.length) {
                    return controller.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final item = controller.feedItems[index];
                  final post = _convertToModelPost(item);

                  if (post == null) return const SizedBox.shrink();

                  return PostItem(
                    post: post,
                    profileId: controller.userId,
                    heroTagPrefix: 'hmv_music',
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
