import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  final String? query;
  const SearchScreen({super.key, this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _historyItems = [
    "chatgpt",
    "figma",
    "idx google",
    "apple tv mobile ui",
    "github",
    "hotstar",
    "zee5",
    "hotstar like ui",
    "apple tv",
    "telegram",
    "Google",
    "wbuhs",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.query != null) {
      _searchController.text = widget.query!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    if (query.isNotEmpty) {
      context.go('/search/$query');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface.withAlpha(153)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153), fontSize: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: _submitSearch,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice search action')),
              );
            },
            icon: const Icon(Icons.mic),
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera search action')),
              );
            },
            icon: const Icon(Icons.camera_alt_outlined),
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(_historyItems[index]);
      },
    );
  }

  Widget _buildHistoryItem(String item) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        _searchController.text = item;
        _submitSearch(item);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.schedule,
              color: theme.colorScheme.onSurface.withAlpha(153),
              size: 22,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 40),
            Icon(
              Icons.north_west,
              color: theme.colorScheme.onSurface.withAlpha(153),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}