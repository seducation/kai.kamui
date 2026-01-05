import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/post.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/profile_page.dart';
import 'package:my_app/comments_screen.dart';

class FullScreenPostDetailPage extends StatefulWidget {
  final Post post;
  final int initialIndex;
  final String profileId;

  const FullScreenPostDetailPage({
    super.key,
    required this.post,
    this.initialIndex = 0,
    required this.profileId,
  });

  @override
  State<FullScreenPostDetailPage> createState() =>
      _FullScreenPostDetailPageState();
}

class _FullScreenPostDetailPageState extends State<FullScreenPostDetailPage> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  late bool _isLiked;
  late int _likeCount;
  int _commentCount = 0;
  late AppwriteService _appwriteService;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _appwriteService = context.read<AppwriteService>();
    _isLiked = false;
    _likeCount = widget.post.stats.likes;
    _commentCount = widget.post.stats.comments;
    _initializeState();
  }

  Future<void> _initializeState() async {
    _prefs = await SharedPreferences.getInstance();
    _fetchCommentCount();
    if (mounted) {
      setState(() {
        _isLiked = _prefs?.getBool(widget.post.id) ?? false;
      });
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
      debugPrint('Error fetching comments: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.post.mediaUrls?.length ?? 0,
            itemBuilder: (context, index) {
              final mediaUrl = widget.post.mediaUrls![index];
              final isVideo = widget.post.type == PostType.video;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Hero(
                      tag: 'post_media_${widget.post.id}_$index',
                      child: isVideo
                          ? _buildVideoPlayer(mediaUrl)
                          : CachedNetworkImage(
                              imageUrl: mediaUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.white),
                            ),
                    ),
                  ),
                  // Gradient for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(150, 0, 0, 0),
                          Colors.transparent,
                          const Color.fromARGB(150, 0, 0, 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          _buildUiOverlay(),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUiOverlay() {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 32, top: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildPostInfo()),
              _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfilePageScreen(profileId: widget.post.author.id),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(
                  widget.post.author.profileImageUrl ?? '',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.post.author.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.post.contentText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(_likeCount),
          onTap: _toggleLike,
          color: _isLiked ? Colors.red : Colors.white,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.comment_bank_outlined,
          label: _formatCount(_commentCount),
          onTap: _openComments,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.reply,
          label: _formatCount(widget.post.stats.shares),
        ),
        const SizedBox(height: 20),
        _buildActionButton(icon: Icons.more_horiz, label: 'More'),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: color ?? Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _buildVideoPlayer(String url) {
    if (_videoController == null || _videoController!.dataSource != url) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }

    if (_videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
