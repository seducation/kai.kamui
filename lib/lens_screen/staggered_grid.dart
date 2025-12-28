import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:my_app/lens_screen/staggered_grid_algorithm.dart';
import 'package:my_app/webview_screen.dart';

class LensStaggeredGrid extends StatefulWidget {
  final List<models.Row> items;
  final ScrollController scrollController;
  final bool isLoading;
  final String? error;

  const LensStaggeredGrid({
    super.key,
    required this.items,
    required this.scrollController,
    required this.isLoading,
    this.error,
  });

  @override
  State<LensStaggeredGrid> createState() => _LensStaggeredGridState();
}

class _LensStaggeredGridState extends State<LensStaggeredGrid> {
  late List<QuiltedGridTile> _pattern;

  @override
  void initState() {
    super.initState();
    _pattern = StaggeredGridAlgorithm.generateRandomPattern();
  }

  void _launchUrl(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${widget.error}'),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverGrid(
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          pattern: _pattern,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = widget.items[index];
          // Dynamically check if the current tile in the pattern is 2x2
          final patternIndex = index % _pattern.length;
          final isBigTile = _pattern[patternIndex].mainAxisCount == 2;

          return GestureDetector(
            onTap: () {
              if (item.data['link'] != null) {
                _launchUrl(context, item.data['link']);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: item.data['imageUrl'] != null
                        ? CachedNetworkImage(
                            imageUrl: item.data['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : Container(color: Colors.grey[300]),
                  ),
                  if (!isBigTile && item.data['title'] != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item.data['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          );
        }, childCount: widget.items.length),
      ),
    );
  }
}
