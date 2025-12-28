import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/models/product.dart';
import 'community_feed.dart';
import 'hero_banner.dart';
import 'status_rail_section.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _lastId;
  bool _hasMore = true;
  static const int _limit = 25;

  @override
  void initState() {
    super.initState();
    _loadInitialContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreContent();
    }
  }

  Future<void> _loadInitialContent() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _lastId = null;
      _products.clear();
    });

    final appwriteService = Provider.of<AppwriteService>(
      context,
      listen: false,
    );
    try {
      final response = await appwriteService.getProducts(limit: _limit);

      final newProducts = response.rows
          .map((row) => Product.fromMap(row.data, row.$id))
          .toList();

      setState(() {
        _products = newProducts;
        if (newProducts.isNotEmpty) {
          _lastId = newProducts.last.id;
        }
        _hasMore = newProducts.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading initial products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final appwriteService = Provider.of<AppwriteService>(
      context,
      listen: false,
    );
    try {
      final response = await appwriteService.getProducts(
        limit: _limit,
        cursor: _lastId,
      );

      final newProducts = response.rows
          .map((row) => Product.fromMap(row.data, row.$id))
          .toList();

      // Remove the first item if it's the same as the cursor (Appwrite cursor pagination includes the cursor item)
      if (newProducts.isNotEmpty && newProducts.first.id == _lastId) {
        newProducts.removeAt(0);
      }

      // If we got nothing new (or only the cursor), we're done
      if (newProducts.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        _products.addAll(newProducts);
        _lastId = newProducts.last.id;
        // If we fetched fewer items than limit (even after removing cursor), we might be at end
        // But safer to assume if count < limit-1 (if cursor removal logic used)
        // Simplest check: if response.rows.length < limit, we are done
        _hasMore = response.rows.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more products: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Prepare header widgets to be passed to CommunityFeed
    final List<Widget> headerWidgets = [
      AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "myapps",
          style: TextStyle(fontSize: 22, color: Colors.black),
        ),
        actions: const [PersistentChip()],
        automaticallyImplyLeading:
            false, // Don't show back button in sliver if not needed
      ),
      HeroBanner(
        items: [
          HeroItem(
            title: "Foundation",
            subtitle: "gvone Original",
            description: "A new empire will rise.",
            imageUrl:
                "https://is3-ssl.mzstatic.com/image/thumb/Features116/v4/e2/2b/8c/e22b8c2c-87e6-2b12-b174-a9c6838b8133/U0YtVFZBLVVTQS1GYW1pbHktQ2Fyb3VzZWwtRm91bmRhdGlvbi5wbmc.png/1679x945.webp",
          ),
          HeroItem(
            title: "LOOT",
            subtitle: "TV Show • Comedy • TV-MA",
            description:
                "A billionaire divorcée continues her hilarious quest to improve the world—and herself.",
            imageUrl:
                "https://is1-ssl.mzstatic.com/image/thumb/Features122/v4/a4/3c/6e/a43c6e4e-941c-2334-f87c-6b3a9a1491e3/U0YtVFZBLVVTQS1GYW1pbHktQ2Fyb3VzZWwtTG9vdC5wbmc/1679x945.webp",
          ),
          HeroItem(
            title: "Severance",
            subtitle: "Drama • Sci-Fi",
            description: "A unique workplace thriller about split memories.",
            imageUrl:
                "https://is3-ssl.mzstatic.com/image/thumb/Features116/v4/3c/f1/c1/3cf1c1f7-4a74-a621-3d5f-149b1390906f/U0YtVFZBLVVTQS1GYW1pbHktQ2Fyb3VzZWwtU2V2ZXJhbmNlLnBuZw/1679x945.webp",
          ),
        ],
      ),
      const SizedBox(height: 20),
      const StatusRailSection(title: "People"),
      const SizedBox(height: 20),
    ];

    return Scaffold(
      body: CommunityFeed(
        products: _products,
        controller: _scrollController,
        headerWidgets: headerWidgets,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }
}

class PersistentChip extends StatefulWidget {
  const PersistentChip({super.key});

  @override
  State<PersistentChip> createState() => _PersistentChipState();
}

class _PersistentChipState extends State<PersistentChip> {
  final TextEditingController _textController = TextEditingController();
  String _chipText = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadChipText();
  }

  Future<void> _loadChipText() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chipText = prefs.getString('chipText') ?? 'Your location';
      _textController.text = _chipText;
    });
  }

  Future<void> _saveChipText(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chipText', text);
    setState(() {
      _chipText = text;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 150,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                onSubmitted: _saveChipText,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveChipText(_textController.text),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: Chip(label: Text(_chipText), avatar: const Icon(Icons.edit)),
      );
    }
  }
}
