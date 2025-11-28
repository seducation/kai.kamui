import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/tabs/about_tab.dart';
import 'package:my_app/tabs/home_tab.dart';
import 'package:my_app/tabs/live_tab.dart';
import 'package:my_app/tabs/podcasts_tab.dart';
import 'package:my_app/tabs/posts_tab.dart';
import 'package:my_app/tabs/shorts_tab.dart';
import 'package:my_app/tabs/videos_tab.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ProfilePageScreen extends StatefulWidget {
  final String profileId;
  const ProfilePageScreen({super.key, required this.profileId});

  @override
  State<ProfilePageScreen> createState() => _ProfilePageScreenState();
}

class _ProfilePageScreenState extends State<ProfilePageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<models.Row> _profileFuture;

  bool _isFollowing = false;
  int _followersCount = 0;
  bool _isCurrentUser = false;

  final List<String> _tabs = ["Home", "Posts", "Videos", "Shorts", "Live", "Podcasts", "About"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfileData();
      }
    });
  }

  void _loadProfileData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return; // Guard against null user

    final appwriteService = Provider.of<AppwriteService>(context, listen: false);

    setState(() {
      _isCurrentUser = widget.profileId == authService.currentUser!.id;
    });

    _profileFuture = appwriteService.getProfile(widget.profileId).then((profile) {
      final List<dynamic> followers = profile.data['followers'] ?? [];
      if (mounted) {
        setState(() {
          _followersCount = followers.length;
          _isFollowing = followers.contains(authService.currentUser!.id);
        });
      }
      return profile;
    });
  }

  Future<void> _toggleFollow() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    final appwriteService = Provider.of<AppwriteService>(context, listen: false);
    final currentUserId = authService.currentUser!.id;

    if (_isCurrentUser) return;

    try {
      if (_isFollowing) {
        await appwriteService.unfollowProfile(
          profileId: widget.profileId,
          followerId: currentUserId,
        );
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount--;
          });
        }
      } else {
        await appwriteService.followProfile(
          profileId: widget.profileId,
          followerId: currentUserId,
        );
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }
      }
    } on AppwriteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<models.Row>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading profile: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No profile found"));
          }

          final profile = snapshot.data!.data;
          final bannerImageUrl = profile['bannerImageUrl'] as String?;
          final profileImageUrl = profile['profileImageUrl'] as String?;
          final name = profile['name'] ?? 'No Name';
          final bio = profile['bio'] ?? '';

          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: 180.0,
                  pinned: true,
                  floating: false,
                  backgroundColor: const Color(0xFF0F0F0F),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: bannerImageUrl != null && bannerImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: bannerImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[800]!,
                            highlightColor: Colors.grey[700]!,
                            child: Container(color: Colors.black),
                          ),
                          errorWidget: (context, url, error) => Container(color: Colors.grey[800]),
                        )
                      : Container(color: Colors.grey[900]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profileImageUrl)
                                : null,
                                child: profileImageUrl == null || profileImageUrl.isEmpty
                                ? const Icon(Icons.person, size: 40, color: Colors.white70)
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$_followersCount subscribers",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                         if (bio.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(
                               bio,
                               style: const TextStyle(color: Colors.grey, fontSize: 13),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                        const SizedBox(height: 16),
                        if (!_isCurrentUser)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing ? const Color(0xFF272727) : Colors.white,
                                foregroundColor: _isFollowing ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: Text(_isFollowing ? "Unsubscribe" : "Subscribe", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.white,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: const [
                HomeTab(),
                PostsTab(),
                VideosTab(),
                ShortsTab(),
                LiveTab(),
                PodcastsTab(),
                AboutTab(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
