import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:provider/provider.dart';
import 'package:my_app/model/post.dart';
import 'package:my_app/model/profile.dart';

class HmvPhotosTabscreen extends StatefulWidget {
  const HmvPhotosTabscreen({super.key});

  @override
  State<HmvPhotosTabscreen> createState() => _HmvPhotosTabscreenState();
}

class _HmvPhotosTabscreenState extends State<HmvPhotosTabscreen> {
  late AppwriteService _appwriteService;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _appwriteService = context.read<AppwriteService>();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final postsResponse = await _appwriteService.getPosts();
      final postFutures = postsResponse.rows.map((row) async {
        final mediaFileIds = row.data['media_files'] as List?;
        if (mediaFileIds == null || mediaFileIds.isEmpty) {
          return null;
        }

        final mediaFiles = await Future.wait(
          mediaFileIds.map((id) => _appwriteService.getFile(id as String)),
        );

        final fileMimeTypes = mediaFiles.map((f) => f.mimeType).toSet();
        if (!fileMimeTypes.any((type) => type.startsWith('image/'))) {
          return null;
        }

        final mediaUrls = mediaFiles
            .map((file) => _appwriteService.getFileViewUrl(file.$id))
            .whereType<String>()
            .toList();

        // Create a dummy profile for now, since we don't need author info in the grid
        final author = Profile(
          id: 'temp_id',
          name: 'temp_name',
          ownerId: 'temp_owner',
          type: 'profile', // Placeholder
          createdAt: DateTime.now(), // Placeholder
        );

        return Post(
          id: row.$id,
          author: author,
          timestamp: DateTime.now(), // Placeholder
          contentText: '', // Placeholder
          mediaUrls: mediaUrls,
          type: PostType.image,
          stats: PostStats(),
        );
      });

      final posts = (await Future.wait(postFutures)).whereType<Post>().toList();

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching data in HmvPhotosTabscreen: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPhotoGrid(),
    );
  }

  Widget _buildPhotoGrid() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 items per row
          crossAxisSpacing: 4, // spacing between columns
          mainAxisSpacing: 4, // spacing between rows
        ),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          if (post.mediaUrls == null || post.mediaUrls!.isEmpty) {
            return const SizedBox.shrink(); // Don't render if no image
          }
          return GestureDetector(
            onTap: () {
              context.push('/post/${post.id}');
            },
            child: Image.network(
              post.mediaUrls!.first,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
