import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_grid.dart';
import '../grid/notices_grid.dart';
import '../grid/friends_grid.dart';
import '../grid/jobs_grid.dart';
import '../grid/services_grid.dart';
import '../grid/stories_grid.dart';

class CommunityFeed extends StatelessWidget {
  final List<Product> products;
  final ScrollController controller;
  final List<Widget> headerWidgets;
  final bool isLoadingMore;

  const CommunityFeed({
    super.key,
    required this.products,
    required this.controller,
    required this.headerWidgets,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && headerWidgets.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return CustomScrollView(
      controller: controller, // Use the controller from parent
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Add headers as slivers
        if (headerWidgets.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => headerWidgets[index],
              childCount: headerWidgets.length,
            ),
          ),

        // Add feed content
        ..._buildFeedSlivers(context),

        // Add loading indicator at the bottom if loading more
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // Add some bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  List<Widget> _buildFeedSlivers(BuildContext context) {
    List<Widget> slivers = [];
    List<Product> currentProductBatch = [];

    // If products match exactly injection intervals or less, logic still holds
    // We just iterate through all products
    for (int i = 0; i < products.length; i++) {
      currentProductBatch.add(products[i]);
      int indexPlusOne = i + 1;

      // Check if we reached an injection point (10, 20, 30...) or end of list
      // Note: We use modulo 10 == 0 but need to handle specific injections
      if (indexPlusOne % 10 == 0 || indexPlusOne == products.length) {
        // Capture the list for this closure
        final batch = List<Product>.from(currentProductBatch);

        // Add current batch of products as a grid
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.all(10.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: batch[index]),
                childCount: batch.length,
              ),
            ),
          ),
        );

        // Inject secondary widget if we hit the exact intervals
        if (indexPlusOne == 10) {
          slivers.add(const SliverToBoxAdapter(child: NoticesGridWidget()));
        } else if (indexPlusOne == 20) {
          slivers.add(const SliverToBoxAdapter(child: FriendsGridWidget()));
        } else if (indexPlusOne == 30) {
          slivers.add(const SliverToBoxAdapter(child: JobsGridWidget()));
        } else if (indexPlusOne == 40) {
          slivers.add(const SliverToBoxAdapter(child: ServicesGridWidget()));
        } else if (indexPlusOne == 50) {
          slivers.add(const SliverToBoxAdapter(child: StoriesGridWidget()));
        }

        // Reset batch
        currentProductBatch = [];
      }
    }

    return slivers;
  }
}
