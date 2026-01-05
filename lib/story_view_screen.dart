import 'package:flutter/material.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/model/story.dart';
import 'package:video_player/video_player.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final Profile profile;

  const StoryViewScreen({
    super.key,
    required this.stories,
    required this.profile,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadStory(widget.stories.first);
  }

  void _loadStory(Story story) {
    _videoController?.dispose();
    if (story.mediaType == 'video') {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl))
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play();
            });
    } else {
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            _loadStory(widget.stories[index]);
          },
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                if (story.mediaType == 'image')
                  Image.network(story.mediaUrl, fit: BoxFit.contain)
                else if (_videoController != null &&
                    _videoController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 40,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            NetworkImage(widget.profile.profileImageUrl ?? ''),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.profile.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Text(
                    story.caption ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(widget.stories.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 2,
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.grey,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
