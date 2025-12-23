import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/following/following_algorithm.dart';
import 'package:my_app/model/post.dart';
import 'package:provider/provider.dart';
import './widgets/post_item.dart';
import 'dart:developer' as developer;

class HMVFollowingTabscreen extends StatefulWidget {
  const HMVFollowingTabscreen({super.key});

  @override
  State<HMVFollowingTabscreen> createState() => _HMVFollowingTabscreenState();
}

class _HMVFollowingTabscreenState extends State<HMVFollowingTabscreen> {
  late FollowingAlgorithm _followingAlgorithm;
  late AppwriteService _appwriteService;
  List<Post> _posts = [];
  String? _userProfileId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _appwriteService = context.read<AppwriteService>();
    _followingAlgorithm = FollowingAlgorithm(
      appwriteService: _appwriteService,
      authService: authService,
    );
    _fetchFollowingPosts();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = await context.read<AuthService>().getCurrentUser();
    if (user != null) {
      try {
        final profile = await _appwriteService.getUserProfiles(ownerId: user.id);
        if (profile.rows.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userProfileId = profile.rows.first.$id;
            });
          }
        }
      } catch (e) {
        developer.log('Error fetching user profile: $e', name: 'HMVFollowingTabscreen', error: e);
      }
    }
  }

  Future<void> _fetchFollowingPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _followingAlgorithm.fetchFollowingPosts();
      developer.log('Fetched posts: ${posts.map((p) => p.id).toList()}', name: 'HMVFollowingTabscreen');
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching posts: $e', name: 'HMVFollowingTabscreen', error: e);
      if (!mounted) return;
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userProfileId == null) {
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
