import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/search_service.dart';
import 'package:provider/provider.dart';
import 'package:my_app/srv_aimode_tabscreen.dart';
import 'package:my_app/srv_app_tabscreen.dart';
import 'package:my_app/srv_chats_tabscreen.dart';
import 'package:my_app/srv_feature_tabscreen.dart';
import 'package:my_app/srv_files_tabscreen.dart';
import 'package:my_app/srv_following_tabscreen.dart';
import 'package:my_app/srv_forum_tabscreen.dart';
import 'package:my_app/srv_music_tabscreen.dart';
import 'package:my_app/srv_photos_tabscreen.dart';
import 'package:my_app/srv_searchtools_tabscreen.dart';
import 'package:my_app/srv_videos_tabscreen.dart';
import 'package:go_router/go_router.dart';

class ResultsSearches extends StatefulWidget {
  final String query;

  const ResultsSearches({super.key, required this.query});

  @override
  State<ResultsSearches> createState() => _ResultsSearchesState();
}

class _ResultsSearchesState extends State<ResultsSearches>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _mainTabController;
  late final SearchService _searchService;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  String _error = '';

  final List<String> _tabs = [
    'ai mode',
    'feature',
    'app',
    'files',
    'following',
    'forum',
    'music',
    'photos',
    'chats',
    'search tools',
    'videos',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    _mainTabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 1,
    );
    _searchService = SearchService(context.read<AppwriteService>());
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await _searchService.search(widget.query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _updateSearchQuery(String newQuery) {
    if (newQuery.isNotEmpty) {
      context.push('/search/$newQuery');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration.collapsed(hintText: 'Search'),
          onSubmitted: _updateSearchQuery,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _updateSearchQuery(_searchController.text),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          isScrollable: true,
          tabs: _tabs.map((String name) => Tab(text: name)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    } else {
      return TabBarView(
        controller: _mainTabController,
        children: [
          SrvAimodeTabscreen(
            searchResults: _searchResults,
            query: widget.query,
          ),
          SrvFeatureTabscreen(searchResults: _searchResults),
          const SrvAppTabscreen(),
          const SrvFilesTabscreen(),
          const SrvFollowingTabscreen(),
          const SrvForumTabscreen(),
          const SrvMusicTabscreen(),
          const SrvPhotosTabscreen(),
          const SrvChatsTabscreen(),
          const SrvSearchtoolsTabscreen(),
          const SrvVideosTabscreen(),
        ],
      );
    }
  }
}
