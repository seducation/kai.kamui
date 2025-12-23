import 'package:flutter/material.dart';
import 'package:my_app/following/following_algorithm.dart';
import 'package:my_app/model/post.dart';
import 'package:provider/provider.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'widgets/post_item.dart';

class HMVFollowingTabscreen extends StatefulWidget {
  const HMVFollowingTabscreen({super.key});

  @override
  State<HMVFollowingTabscreen> createState() => _HMVFollowingTabscreenState();
}

class _HMVFollowingTabscreenState extends State<HMVFollowingTabscreen> {
  late FollowingAlgorithm _followingAlgorithm;
  List<Post> _posts = [];
  String? _userProfileId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final appwriteService = context.read<AppwriteService>();
    final authService = context.read<AuthService>();
    _followingAlgorithm = FollowingAlgorithm(
      appwriteService: appwriteService,
      authService: authService,
    );
    _fetchFollowingPosts();
  }

  Future<void> _fetchFollowingPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _followingAlgorithm.fetchFollowingPosts();
      if (!mounted) return;
      setState(() {
        _posts = result.posts;
        _userProfileId = result.userProfileId;
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

  @override
  Widget build(BuildContext context) {
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
          return PostItem(post: post, profileId: _userProfileId!);
        },
      ),
    );
  }
}
