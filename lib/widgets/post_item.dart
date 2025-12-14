import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/post.dart';
import 'package:my_app/widgets/post_options_menu.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final String profileId;

  const PostItem({super.key, required this.post, required this.profileId});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == PostType.video && widget.post.mediaUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      widget.post.isLiked = !widget.post.isLiked;
      if (widget.post.isLiked) {
        widget.post.stats.likes++;
      } else {
        widget.post.stats.likes--;
      }
    });
  }

  void _toggleSaved() {
    setState(() {
      widget.post.isSaved = !widget.post.isSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (widget.post.contentText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(widget.post.contentText),
            ),
          _buildMedia(),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    switch (widget.post.type) {
      case PostType.image:
        return CachedNetworkImage(
          imageUrl: widget.post.mediaUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(height: 250, color: Colors.grey[300]),
          errorWidget: (context, url, error) => Container(height: 250, color: Colors.red[100], child: const Icon(Icons.error)),
        );
      case PostType.video:
        if (_controller != null && _controller!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller!),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                    });
                  },
                  child: Icon(
                    _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: const Color.fromRGBO(255, 255, 255, 0.7),
                    size: 60,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(height: 250, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator()));
        }
      case PostType.linkPreview:
        if (widget.post.linkUrl != null) {
          return AnyLinkPreview(
            link: widget.post.linkUrl!,
            displayDirection: UIDirection.uiDirectionHorizontal,
            showMultimedia: true,
            bodyMaxLines: 5,
            bodyTextOverflow: TextOverflow.ellipsis,
            titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            bodyStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            errorWidget: Container(height: 100, color: Colors.grey[300], child: const Center(child: Text('Could not load preview'))),
            cache: const Duration(days: 7),
            backgroundColor: Colors.grey[100],
            borderRadius: 12,
            urlLaunchMode: LaunchMode.inAppWebView,
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(widget.post.author.profileImageUrl ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
            radius: 20,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post.author.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  timeago.format(widget.post.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          PostOptionsMenu(post: widget.post, profileId: widget.profileId),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionItem(
                widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                _formatCount(widget.post.stats.likes),
                color: widget.post.isLiked ? Colors.red : Colors.grey[600],
                onTap: _toggleLike,
              ),
              const SizedBox(width: 20),
              _buildActionItem(Icons.comment, widget.post.stats.comments.toString(), onTap: () {}),
              const SizedBox(width: 20),
              _buildActionItem(Icons.repeat, widget.post.stats.shares.toString(), onTap: () {}),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleSaved,
                child: Icon(
                  widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.grey[600],
                  size: 22,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.share, color: Colors.grey[600], size: 22),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color ?? Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}k";
    }
    return count.toString();
  }
}
