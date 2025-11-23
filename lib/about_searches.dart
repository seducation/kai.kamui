import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutSearches extends StatefulWidget {
  const AboutSearches({super.key});

  @override
  State<AboutSearches> createState() => _AboutSearchesState();
}

class _AboutSearchesState extends State<AboutSearches> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a network request
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      // Mock search results
      _searchResults = List.generate(
        10,
        (index) => {
          'name': '$query result $index',
          'description': 'This is a mock description for result $index',
        },
      );
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildToolIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          child: Icon(icon, size: 28, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildSubscriptionTile(String name) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialLayout() {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                const Center(
                  child: Text(
                    'My App',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolIcon(Icons.science_outlined, 'Labs'),
                    _buildToolIcon(Icons.list_alt_outlined, 'Lits'),
                    _buildToolIcon(Icons.payment, 'Payment'),
                    _buildToolIcon(Icons.construction_outlined, 'Tools'),
                    _buildToolIcon(Icons.history, 'History'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Subscription',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildSubscriptionTile('R4'),
                          const SizedBox(height: 8),
                          _buildSubscriptionTile('R5'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildSubscriptionTile('R1')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSubscriptionTile('R2')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSubscriptionTile('R3'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'show more',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolIcon(Icons.settings, 'S1'),
                    _buildToolIcon(Icons.settings, 'S2'),
                    _buildToolIcon(Icons.settings, 'S3'),
                    _buildToolIcon(Icons.settings, 'S4'),
                    _buildToolIcon(Icons.settings, 'S5'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolIcon(Icons.settings, 'S6'),
                    _buildToolIcon(Icons.settings, 'S7'),
                    _buildToolIcon(Icons.settings, 'S8'),
                    _buildToolIcon(Icons.settings, 'S9'),
                    _buildToolIcon(Icons.settings, 'S10'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Insight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Center(
                    child: Text(
                      'Graph Area',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        context.go('/profile');
                      },
                    ),
                    const SizedBox(width: 8),
                    // Placeholder for weather widget
                    const Row(
                      children: [
                        Icon(Icons.wb_sunny, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('25°C', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Placeholder for location widget
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('New York', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ), 
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchResults = [];
              });
            },
          ),
          title: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          backgroundColor: Colors.white,
          pinned: true,
        ),
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No results found.'),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final hit = _searchResults[index];
                return ListTile(
                  title: Text(hit['name'] ?? 'No name'),
                  subtitle: Text(hit['description'] ?? ''),
                );
              },
              childCount: _searchResults.length,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isSearching ? _buildSearchLayout() : _buildInitialLayout(),
    );
  }
}
