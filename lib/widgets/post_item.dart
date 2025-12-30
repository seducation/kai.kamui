import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/comments_screen.dart';
import 'package:my_app/model/post.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/profile_page.dart';
import 'package:my_app/widgets/post_options_menu.dart';
import 'package:my_app/post_detail_screen.dart';
import 'package:my_app/full_screen_post_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final String profileId;
  final String? heroTagPrefix;

  const PostItem({
    super.key,
    required this.post,
    required this.profileId,
    this.heroTagPrefix,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late bool _isLiked;
  late bool _isSaved;
  late int _likeCount;
  int _commentCount = 0;
  late AppwriteService _appwriteService;
  SharedPreferences? _prefs;
  VideoPlayerController? _controller;
  int _currentPage = 0;
  List<Profile> _cachedAuthors = [];
  bool _isLoadingAuthors = false;

  // Sequential playlist state
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    _appwriteService = context.read<AppwriteService>();
    _isLiked = false;
    _isSaved = false;
    _likeCount = widget.post.stats.likes;
    _commentCount = widget.post.stats.comments;
    _initializeState();

    if (widget.post.type == PostType.video &&
        widget.post.mediaUrls != null &&
        widget.post.mediaUrls!.isNotEmpty) {
      _initializeVideoPlaylist();
    }
  }

  Future<void> _initializeVideoPlaylist() async {
    if (widget.post.mediaUrls == null || widget.post.mediaUrls!.isEmpty) {
      return;
    }

    _currentVideoIndex = 0;
    await _loadVideo(_currentVideoIndex);
  }

  Future<void> _loadVideo(int index) async {
    if (widget.post.mediaUrls == null ||
        index >= widget.post.mediaUrls!.length) {
      return;
    }

    // Dispose existing controller
    _controller?.removeListener(_videoListener);
    _controller?.dispose();

    // Create and initialize new controller
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.mediaUrls![index]),
    );

    await _controller!.initialize();
    _controller!.addListener(_videoListener);

    if (mounted) {
      setState(() {
        _currentVideoIndex = index;
      });
      // Auto-play if not the first video or if user had started playback
      if (index > 0) {
        _controller!.play();
      }
    }
  }

  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    // Check if video ended
    if (_controller!.value.position >= _controller!.value.duration) {
      // Auto-advance to next video
      if (_currentVideoIndex < (widget.post.mediaUrls?.length ?? 0) - 1) {
        _loadVideo(_currentVideoIndex + 1);
      }
    }

    // Update UI for progress
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeState() async {
    _prefs = await SharedPreferences.getInstance();
    final user = await _appwriteService.getUser();
    if (user != null) {
      _fetchCommentCount();
      // Check server status for like
      final serverLiked = await _appwriteService.hasUserLikedPost(
        userId: user.$id,
        postId: widget.post.id,
      );
      if (mounted) {
        setState(() {
          _isLiked = serverLiked;
        });
      }
    }

    // Prefetch authors if needed for the UI
    final bool hasAuthors =
        widget.post.authorIds != null && widget.post.authorIds!.isNotEmpty;
    final bool hasMultipleProfiles =
        widget.post.profileIds != null && widget.post.profileIds!.length > 1;

    if (hasAuthors || hasMultipleProfiles) {
      _fetchPostAuthorsLocal();
    }

    if (mounted) {
      setState(() {
        if (user == null) {
          _isLiked = _prefs?.getBool(widget.post.id) ?? false;
        }
        _isSaved = _prefs?.getBool('saved_${widget.post.id}') ?? false;
      });
    }
  }

  Future<void> _fetchPostAuthorsLocal() async {
    if (!mounted || _isLoadingAuthors) return;
    setState(() {
      _isLoadingAuthors = true;
    });

    try {
      final profiles = await _fetchPostAuthors();
      if (mounted) {
        setState(() {
          _cachedAuthors = profiles;
        });
      }
    } catch (e) {
      // Handle error silently or log
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAuthors = false;
        });
      }
    }
  }

  Future<void> _fetchCommentCount() async {
    try {
      final comments = await _appwriteService.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _commentCount = comments.total;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _toggleLike() async {
    if (_prefs == null) return;

    final user = await _appwriteService.getUser();
    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like posts.')),
      );
      return;
    }

    final newLikedState = !_isLiked;
    final newLikeCount = newLikedState ? _likeCount + 1 : _likeCount - 1;

    if (mounted) {
      setState(() {
        _isLiked = newLikedState;
        _likeCount = newLikeCount;
      });
    }

    try {
      // Optimistic update for the counter
      await _appwriteService.updatePostLikes(
        widget.post.id,
        newLikeCount,
        widget.post.timestamp.toIso8601String(),
      );

      // Update the collection
      if (newLikedState) {
        await _appwriteService.likePost(
          userId: user.$id,
          postId: widget.post.id,
        );
      } else {
        await _appwriteService.unlikePost(
          userId: user.$id,
          postId: widget.post.id,
        );
      }

      await _prefs!.setBool(widget.post.id, newLikedState);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !newLikedState;
          _likeCount = _isLiked ? newLikeCount + 1 : newLikeCount - 1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleSaved() async {
    if (_prefs == null) return;
    final user = await _appwriteService.getUser();
    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save posts.')),
      );
      return;
    }

    final newSavedState = !_isSaved;

    if (mounted) {
      setState(() {
        _isSaved = newSavedState;
      });
    }

    try {
      if (newSavedState) {
        await _appwriteService.savePost(
          profileId: widget.profileId,
          postId: widget.post.id,
        );
      } else {
        await _appwriteService.unsavePost(
          profileId: widget.profileId,
          postId: widget.post.id,
        );
      }
      await _prefs!.setBool('saved_${widget.post.id}', newSavedState);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = !newSavedState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update saved status. Please try again.'),
          ),
        );
      }
    }
  }

  void _openComments() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(post: widget.post),
      ),
    );

    if (result == true) {
      _fetchCommentCount();
    }
  }

  Future<List<Profile>> _fetchPostAuthors() async {
    final allProfileIds = <String>{};
    if (widget.post.profileIds != null) {
      allProfileIds.addAll(widget.post.profileIds!);
    }
    if (widget.post.authorIds != null) {
      allProfileIds.addAll(widget.post.authorIds!);
    }

    if (allProfileIds.isEmpty) {
      return [];
    }

    // Simple deduplication if authorIds and profileIds overlap
    // But since we are modifying UI, let's just fetch all unique IDs
    // Note: authorIds might be user IDs, not profile IDs depending on implementation
    // Assuming here they are profile IDs or fetchable via getProfile.
    // If they are user IDs and getProfile handles it, great.

    // Let's filter out duplicate IDs before mapping
    final uniqueIds = allProfileIds.toSet().toList();

    final profileFutures = uniqueIds.map(
      (id) => _appwriteService.getProfile(id),
    );

    // We might have failures if some IDs are invalid, so robust error handling would be good
    // But keeping it simple as per original code structure
    try {
      final profileRows = await Future.wait(profileFutures);
      return profileRows.map((row) => Profile.fromRow(row)).toList();
    } catch (e) {
      // If fetching fails, return empty list or handle appropriately
      return [];
    }
  }

  void _showPostAuthors() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Use cached authors if available to show immediately
        // and fetch fresh if needed, or just rely on cached since fetching happened at init
        if (_isLoadingAuthors) {
          return const Center(child: CircularProgressIndicator());
        }

        // If we haven't fetched yet (maybe failed?), try again or use future builder
        if (_cachedAuthors.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "In this post",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _cachedAuthors.length,
                    itemBuilder: (context, index) {
                      final profile = _cachedAuthors[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            profile.profileImageUrl ?? '',
                          ),
                        ),
                        title: Text(profile.name),
                        onTap: () {
                          Navigator.pop(
                            context,
                          ); // Close sheet before navigating
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePageScreen(profileId: profile.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Profile>>(
          future: _fetchPostAuthors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Error loading authors')),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No authors to show')),
              );
            }

            final profiles = snapshot.data!;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "In this post",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            profile.profileImageUrl ?? '',
                          ),
                        ),
                        title: Text(profile.name),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePageScreen(profileId: profile.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildMedia(context),
          if (widget.post.type == PostType.video) _buildVideoProgressBar(),
          _buildContentText(context),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: _buildActionBar(),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }

  Widget _buildContentText(BuildContext context) {
    final hasTitle =
        widget.post.linkTitle != null && widget.post.linkTitle!.isNotEmpty;
    final hasContent = widget.post.contentText.isNotEmpty;

    if (!hasTitle && !hasContent) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Text: linkTitle (if exists)
          if (hasTitle)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: widget.post),
                  ),
                );
              },
              child: Text(
                widget.post.linkTitle!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          // Secondary Text: contentText (if exists)
          if (hasContent) ...[
            if (hasTitle) const SizedBox(height: 8),
            Text(
              widget.post.contentText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    switch (widget.post.type) {
      case PostType.image:
        return _buildImageContent(context);
      case PostType.video:
        if (_controller != null && _controller!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              onDoubleTap: () {
                if (!_isLiked) _toggleLike();
              },
              onLongPress: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FullScreenPostDetailPage(
                          post: widget.post,
                          initialIndex: _currentVideoIndex,
                          profileId: widget.profileId,
                        ),
                  ),
                );
              },
              child: Hero(
                tag:
                    '${widget.heroTagPrefix ?? 'post_media'}_${widget.post.id}_0',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    // Overlay controls (only buttons, no progress bar)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Play/Pause button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _controller!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller!.value.isPlaying
                                      ? _controller!.pause()
                                      : _controller!.play();
                                });
                              },
                            ),
                          ),
                          // Time display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPlaylistTimeDisplay(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          // Volume/Mute button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _controller!.value.volume > 0
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller!.setVolume(
                                    _controller!.value.volume > 0 ? 0.0 : 1.0,
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(
            height: 250,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      case PostType.linkPreview:
        return _buildLinkPreview(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader(BuildContext context) {
    final handleColor = Colors.grey[600];
    final bool hasAuthors =
        widget.post.authorIds != null && widget.post.authorIds!.isNotEmpty;
    final bool hasMultipleProfiles =
        widget.post.profileIds != null && widget.post.profileIds!.length > 1;

    // Show stack if there is at least one author OR more than one profile.
    // In reality, if it's just the main author, we use standard view.
    // We only use the stack if there are multiple involved entities.
    final bool showStack = (hasAuthors || hasMultipleProfiles);

    return GestureDetector(
      onTap: () {
        if (showStack) {
          _showPostAuthors();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfilePageScreen(profileId: widget.post.author.id),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          children: [
            if (showStack)
              // If we have cached authors, show them. Else show loading or fallback.
              SizedBox(
                width: 60, // Sufficient width for overlap
                height: 40,
                child: Stack(
                  children: [
                    if (_isLoadingAuthors && _cachedAuthors.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_cachedAuthors.isNotEmpty)
                      ...List.generate(
                        _cachedAuthors.length > 3 ? 3 : _cachedAuthors.length,
                        (index) {
                          // Reverse index for rendering order if we want first on top?
                          // Usually last in list is top in Stack.
                          // We want first author on LEFT (bottom of stack visually or handled by position)
                          // Let's position them: 0 -> Left, 1 -> mid, 2 -> right
                          // To make them overlap nicely, the one on the RIGHT should probably be on TOP or BOTTOM depending on style.
                          // Request: "horizontally overlapping each other"

                          // Let's render first item at left (0), second at (15), third at (30).
                          // We render them in reverse order so the first one is ON TOP? or normal order?
                          // Material design usually puts 1st on top or last on top.
                          // Let's try: Index 0 at left: 0. Index 2 at left: 30.
                          // If we render 0, then 1, then 2 -> 2 is on top of 1.
                          final profile = _cachedAuthors[index];
                          return Positioned(
                            left: index * 15.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ), // White border for separation
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: CachedNetworkImageProvider(
                                  profile.profileImageUrl ?? '',
                                ),
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      // Fallback if no authors found yet or empty list
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(
                            widget.post.author.profileImageUrl ?? '',
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Builder(
                builder: (context) {
                  final bool isValidUrl =
                      widget.post.author.profileImageUrl != null &&
                      (widget.post.author.profileImageUrl!.startsWith('http') ||
                          widget.post.author.profileImageUrl!.startsWith(
                            'https',
                          ));
                  if (isValidUrl) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(
                        widget.post.author.profileImageUrl!,
                      ),
                      backgroundColor: Colors.grey[200],
                    );
                  } else {
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                    );
                  }
                },
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.post.author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.post.originalAuthor != null)
                        Flexible(
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Text(
                                'by',
                                style: TextStyle(
                                  color: handleColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.post.originalAuthor!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    timeago.format(widget.post.timestamp),
                    style: TextStyle(color: handleColor, fontSize: 14),
                  ),
                ],
              ),
            ),
            PostOptionsMenu(
              post: widget.post,
              profileId: widget.profileId,
              isSaved: _isSaved,
              onSaveToggle: _toggleSaved,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (widget.post.mediaUrls == null || widget.post.mediaUrls!.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error, color: Colors.grey),
        ),
      );
    }

    if (widget.post.mediaUrls!.length > 1) {
      return Column(
        children: [
          SizedBox(
            height: 400,
            child: PageView.builder(
              itemCount: widget.post.mediaUrls!.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onDoubleTap: () {
                    if (!_isLiked) _toggleLike();
                  },
                  onLongPress: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            FullScreenPostDetailPage(
                              post: widget.post,
                              initialIndex: index,
                              profileId: widget.profileId,
                            ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'post_media_${widget.post.id}_$index',
                    child: CachedNetworkImage(
                      imageUrl: widget.post.mediaUrls![index],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => AspectRatio(
                        aspectRatio: 1,
                        child: Container(color: Colors.grey[200]),
                      ),
                      errorWidget: (context, url, error) => AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.post.mediaUrls!.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 2.0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              );
            }),
          ),
        ],
      );
    } else {
      final bool isValidUrl =
          widget.post.mediaUrls!.first.startsWith('http') ||
          widget.post.mediaUrls!.first.startsWith('https');
      return GestureDetector(
        onDoubleTap: () {
          if (!_isLiked) _toggleLike();
        },
        onLongPress: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FullScreenPostDetailPage(
                    post: widget.post,
                    initialIndex: 0,
                    profileId: widget.profileId,
                  ),
            ),
          );
        },
        onTap: () {
          // Handle image tap if necessary
        },
        child: isValidUrl
            ? Hero(
                tag: 'post_media_${widget.post.id}_0',
                child: CachedNetworkImage(
                  imageUrl: widget.post.mediaUrls!.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => AspectRatio(
                    aspectRatio: 1,
                    child: Container(color: Colors.grey[200]),
                  ),
                  errorWidget: (context, url, error) => AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                ),
              )
            : AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
              ),
      );
    }
  }

  Widget _buildLinkPreview(BuildContext context) {
    if (widget.post.linkUrl == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(widget.post.linkUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.inAppWebView);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: AnyLinkPreview(
          link: widget.post.linkUrl!,
          displayDirection: UIDirection.uiDirectionHorizontal,
          showMultimedia: true,
          bodyMaxLines: 3,
          bodyTextOverflow: TextOverflow.ellipsis,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          bodyStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          errorWidget: Container(
            height: 100,
            color: Colors.grey[300],
            child: const Center(child: Text('Could not load preview')),
          ),
          cache: const Duration(days: 7),
          backgroundColor: Colors.grey[100],
          borderRadius: 8,
          removeElevation: true,
          urlLaunchMode: LaunchMode.inAppWebView,
        ),
      ),
    );
  }

  Widget _buildVideoProgressBar() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // Calculate cumulative position and total duration
    final cumulativeData = _getCumulativeProgress();
    final videoCount = widget.post.mediaUrls?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust track width to account for Slider internal padding (usually 12 (thumb radius/2) or similar)
          // Material Slider typically has 24px total padding on sides (12 each)
          final totalTrackWidth = constraints.maxWidth - 24;

          return Stack(
            alignment: Alignment.center,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12.0,
                  ),
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Theme.of(context).primaryColor,
                ),
                child: Slider(
                  value: cumulativeData['position']!.toDouble(),
                  min: 0.0,
                  max: cumulativeData['total']!.toDouble(),
                  onChanged: (value) {
                    _seekToPlaylistPosition(value.toInt());
                  },
                ),
              ),
              // Boundary markers
              if (videoCount > 1)
                ...List.generate(videoCount - 1, (index) {
                  final progressPercent = (index + 1) / videoCount;
                  return Positioned(
                    left:
                        12 +
                        (totalTrackWidth * progressPercent) -
                        1, // -1 to center 2px divider
                    child: Container(
                      width: 2,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Map<String, int> _getCumulativeProgress() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return {'position': 0, 'total': 0};
    }

    // For single video, return simple position
    if (widget.post.mediaUrls == null || widget.post.mediaUrls!.length == 1) {
      return {
        'position': _controller!.value.position.inMilliseconds,
        'total': _controller!.value.duration.inMilliseconds,
      };
    }

    // Calculate total duration (approximation for unloaded videos)
    int total =
        _controller!.value.duration.inMilliseconds *
        widget.post.mediaUrls!.length;

    // Calculate cumulative position
    int position =
        (_currentVideoIndex * _controller!.value.duration.inMilliseconds) +
        _controller!.value.position.inMilliseconds;

    return {'position': position, 'total': total};
  }

  void _seekToPlaylistPosition(int milliseconds) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (widget.post.mediaUrls == null || widget.post.mediaUrls!.isEmpty) {
      return;
    }

    final avgVideoDuration = _controller!.value.duration.inMilliseconds;

    // Calculate which video and position
    final targetVideoIndex = milliseconds ~/ avgVideoDuration;
    final positionInVideo = milliseconds % avgVideoDuration;

    if (targetVideoIndex != _currentVideoIndex &&
        targetVideoIndex < widget.post.mediaUrls!.length) {
      // Load different video
      _loadVideo(targetVideoIndex).then((_) {
        if (mounted && _controller != null) {
          _controller!.seekTo(Duration(milliseconds: positionInVideo));
        }
      });
    } else {
      // Same video, just seek
      _controller!.seekTo(Duration(milliseconds: positionInVideo));
    }
  }

  String _getPlaylistTimeDisplay() {
    final cumulativeData = _getCumulativeProgress();
    final position = Duration(milliseconds: cumulativeData['position']!);
    final total = Duration(milliseconds: cumulativeData['total']!);
    return '${_formatDuration(position)} / ${_formatDuration(total)}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _toggleLike,
              child: _buildActionItem(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                _formatCount(_likeCount),
                color: _isLiked ? Colors.red : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _openComments,
              child: _buildActionItem(Icons.comment, _commentCount.toString()),
            ),
            const SizedBox(width: 24),
            _buildActionItem(Icons.repeat, widget.post.stats.shares.toString()),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _toggleSaved,
              child: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 24),
            Icon(Icons.share, color: Colors.grey[600], size: 22),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color ?? Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
