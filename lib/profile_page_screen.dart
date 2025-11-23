import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/psv_about_tabscreen.dart';
import 'package:my_app/psv_home_tabscreen.dart';
import 'package:my_app/psv_live_tabscreen.dart';
import 'package:my_app/psv_podcasts_tabscreen.dart';
import 'package:my_app/psv_shorts_tabscreen.dart';
import 'package:my_app/psv_videos_tabscreen.dart';
import 'package:shimmer/shimmer.dart';

class ChannelProfilePage extends StatefulWidget {
  final String name;
  final String imageUrl;
  const ChannelProfilePage({super.key, required this.name, required this.imageUrl});

  @override
  State<ChannelProfilePage> createState() => _ChannelProfilePageState();
}

class _ChannelProfilePageState extends State<ChannelProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab Names corresponding to the screenshot
  final List<String> _tabs = ["Home", "Videos", "Shorts", "Live", "Podcasts", "About"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // 1. THE HERO BANNER (SliverAppBar)
            SliverAppBar(
              expandedHeight: 180.0, // Height of the banner
              pinned: true,
              floating: true,
              snap: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.go('/search'),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.black),
                  ),
                ),
              ),
            ),

            // 2. PROFILE INFO SECTION (Non-sticky content)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and Title Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.name,
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.check_circle, size: 16, color: Colors.grey[600])
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "@${widget.name.replaceAll(' ', '')} • 8.12M subscribers • 2.4K videos",
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      "Welcome to The Official ${widget.name} channel! Subscribe and follow for the latest updates. ...more",
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Link
                    Text(
                      "a.atvi.com/PlayBlackOps7 and 9 more links",
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.onPrimary,
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text("Subscribe", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor: theme.colorScheme.onSecondaryContainer,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text("Visit shop", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. STICKY TAB BAR
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.secondary,
                  indicatorColor: theme.colorScheme.primary,
                  dividerColor: Colors.transparent, // Removes the line below tabs
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                ),
              ),
              pinned: true,
            ),
          ];
        },
        // 4. TAB CONTENT BODY
        body: TabBarView(
          controller: _tabController,
          children: const [
            PsvHomeTabscreen(),
            PsvVideosTabscreen(),
            PsvShortsTabscreen(),
            PsvLiveTabscreen(),
            PsvPodcastsTabscreen(),
            PsvAboutTabscreen(),
          ],
        ),
      ),
    );
  }
}

// Helper class to make the TabBar stick to the top
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
