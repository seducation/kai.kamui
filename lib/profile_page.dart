import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/add_product.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/tabs/about_tab.dart';
import 'package:my_app/tabs/home_tab.dart';
import 'package:my_app/tabs/live_tab.dart';
import 'package:my_app/tabs/playlists_tab.dart';
import 'package:my_app/tabs/posts_tab.dart';
import 'package:my_app/tabs/products_tab.dart';
import 'package:my_app/tabs/servicesprofile_tab.dart';
import 'package:my_app/tabs/videos_tab.dart';
import 'package:my_app/tabs/tv_posts_tab.dart'; // Add this import
import 'package:my_app/widgets/edit_profile_fab.dart';
import 'package:my_app/widgets/more_options_modal.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_app/tabs/jobs_tab.dart';
import 'package:my_app/add_notice_screen.dart';
import 'package:my_app/add_service_screen.dart';
import 'package:my_app/add_job_screen.dart';

class ProfilePageScreen extends StatefulWidget {
  final String profileId;
  const ProfilePageScreen({super.key, required this.profileId});

  @override
  State<ProfilePageScreen> createState() => _ProfilePageScreenState();
}

class _ProfilePageScreenState extends State<ProfilePageScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late AppwriteService _appwriteService;
  late AuthService _authService;
  Profile? _profile; // The profile being VIEWED
  // _currentUserProfileId is now managed by AuthService's activeIdentityId

  bool _isFollowing = false;
  int _followersCount = 0;
  bool _isLoading = true;

  String? _fullProfileImageUrl;
  String? _fullBannerImageUrl;

  List<String> _tabs = [];
  List<Widget> _tabViews = [];

  @override
  void initState() {
    super.initState();
    _appwriteService = context.read<AppwriteService>();
    _authService = context.read<AuthService>();
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController != null) {
      _tabController!.addListener(_handleTabSelection);
    }
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted || user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Ensure we have an active identity. If not, try to set the generic one.
      if (_authService.activeIdentityId == null) {
        final mainProfileId = await _appwriteService.getMainUserProfileId(
          user.id,
        );
        if (mainProfileId != null) {
          _authService.setActiveIdentity(
            mainProfileId,
            'private',
          ); // Default to private/main
        }
      }

      final profileRow = await _appwriteService.getProfile(widget.profileId);
      if (!mounted) return;

      _profile = Profile.fromRow(profileRow);

      final profileImageId = _profile!.profileImageUrl;
      final bannerImageId = profileRow.data['bannerImageUrl'];

      _fullProfileImageUrl =
          (profileImageId != null && profileImageId.isNotEmpty)
              ? _appwriteService.getFileViewUrl(profileImageId)
              : null;

      _fullBannerImageUrl = (bannerImageId != null && bannerImageId.isNotEmpty)
          ? _appwriteService.getFileViewUrl(bannerImageId)
          : null;

      // Use the new service to get the count
      final count = await _appwriteService.getFollowerCount(
        targetId: widget.profileId,
      );
      _followersCount = count;

      if (_authService.activeIdentityId != null) {
        _isFollowing = await _appwriteService.isFollowing(
          currentUserId:
              user.id, // Not strictly used if activeIdentityId is passed
          targetId: widget.profileId,
          activeIdentityId: _authService.activeIdentityId,
        );
      } else {
        _isFollowing = false;
      }

      _initializeTabs();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeTabs() {
    _tabs = _getTabsForProfile(_profile);
    _tabViews = _getTabViewsForProfile(_profile);
    _tabController?.dispose(); // Dispose old controller if exists
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(_handleTabSelection);
  }

  List<String> _getTabsForProfile(Profile? profile) {
    // TV Profiles: Home, TV Posts, About
    if (profile?.type == 'tv') {
      return ["Home", "TV Posts", "About"];
    }

    // Standard Profiles
    final baseTabs = [
      "Home",
      "Posts",
      "Videos",
      "Services",
      "Live",
      "Playlists",
    ];

    if (profile?.type == 'business') {
      baseTabs.add("Products");
      baseTabs.add("Jobs");
    }

    baseTabs.add("About");
    return baseTabs;
  }

  Future<void> _toggleFollow() async {
    final activeId = _authService.activeIdentityId;

    if (activeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active profile selected. Please select a profile.'),
        ),
      );
      return;
    }

    final originalFollowState = _isFollowing;
    final originalFollowersCount = _followersCount;

    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _followersCount++;
      } else {
        _followersCount--;
      }
    });

    try {
      final isAnonymous = _authService.activeIdentityType == 'private';

      if (_isFollowing) {
        await _appwriteService.followEntity(
          senderId: activeId,
          targetId: widget.profileId,
          isAnonymous: isAnonymous,
          targetType: 'profile',
        );
      } else {
        await _appwriteService.unfollowEntity(
          senderId: activeId,
          targetId: widget.profileId,
          targetType: 'profile',
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Revert state on error
      setState(() {
        _isFollowing = originalFollowState;
        _followersCount = originalFollowersCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the viewed profile belongs to the current user (by ownerId)
    final isCurrentUser = _profile != null &&
        _authService.currentUser != null &&
        _profile!.ownerId == _authService.currentUser!.id;
    return Scaffold(
      body: _isLoading || _tabController == null
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text("Profile not found"))
              : NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        expandedHeight: 180.0,
                        pinned: true,
                        floating: false,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.cast, color: Colors.black),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.black),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.black,
                            ),
                            onPressed: () {},
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: _fullBannerImageUrl != null &&
                                  _fullBannerImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _fullBannerImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(color: Colors.grey[200]),
                                )
                              : Container(color: Colors.grey[200]),
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
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        _fullProfileImageUrl != null &&
                                                _fullProfileImageUrl!.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                _fullProfileImageUrl!,
                                              )
                                            : null,
                                    child: _fullProfileImageUrl == null ||
                                            _fullProfileImageUrl!.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey[600],
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _profile!.name,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            if (_profile?.type == 'tv') ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.tv,
                                                        size: 14,
                                                        color: Colors.white),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'TV',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$_followersCount followers",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_profile!.bio != null &&
                                  _profile!.bio!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _profile!.bio!,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              if (!isCurrentUser)
                                _isFollowing
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _toggleFollow,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[200],
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                              ),
                                              child: const Text(
                                                "Unfollow",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              _showMoreOptions(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey[200],
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _toggleFollow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: const Text(
                                            "Follow",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.black54,
                            indicatorColor: Colors.black,
                            dividerColor: Colors.transparent,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            tabs: _tabs
                                .map((String name) => Tab(text: name))
                                .toList(),
                          ),
                        ),
                        pinned: true,
                      ),
                    ];
                  },
                  body: TabBarView(
                      controller: _tabController, children: _tabViews),
                ),
      floatingActionButton: isCurrentUser
          ? FloatingActionButton(
              onPressed: () {
                _showAddMenu(context);
              },
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final isBusiness = _profile?.type == 'business';
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) =>
                        ChannelSettingsDialog(profileId: widget.profileId),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_alert),
                title: const Text('Add Notice'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddNoticeScreen(profileId: widget.profileId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Add Service'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddServiceScreen(profileId: widget.profileId),
                    ),
                  );
                },
              ),
              if (isBusiness) ...[
                const Divider(),
                const Text(
                  'Business Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Add Jobs'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddJobScreen(profileId: widget.profileId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('Add Products'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddProductScreen(profileId: widget.profileId),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const MoreOptionsModal();
      },
    );
  }

  List<Widget> _getTabViewsForProfile(Profile? profile) {
    // TV Profile Views
    if (profile?.type == 'tv') {
      return [
        HomeTab(profileId: widget.profileId),
        TVPostsTab(profileId: widget.profileId), // Staggered grid for TV
        AboutTab(profileId: widget.profileId),
      ];
    }

    // Standard Profile Views
    final List<Widget> baseTabViews = [
      HomeTab(profileId: widget.profileId),
      PostsTab(profileId: widget.profileId),
      VideosTab(profileId: widget.profileId),
      Servicesprofiletab(profileId: widget.profileId),
      LiveTab(profileId: widget.profileId),
      PlaylistsTab(profileId: widget.profileId),
    ];

    if (profile != null && profile.type == 'business') {
      baseTabViews.add(ProductsTab(profileId: widget.profileId));
      baseTabViews.add(JobsTab(profileId: widget.profileId));
    }

    baseTabViews.add(AboutTab(profileId: widget.profileId));
    return baseTabViews;
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
