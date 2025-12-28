import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math';

class StaggeredGridAlgorithm {
  static const List<List<QuiltedGridTile>> _tileBlocks = [
    // Block 1: Large tile on left (2x2), two small on right
    [QuiltedGridTile(2, 2), QuiltedGridTile(1, 1), QuiltedGridTile(1, 1)],
    // Block 2: Large tile on right (2x2), two small on left (adjusted order for 3-col fit)
    [QuiltedGridTile(1, 1), QuiltedGridTile(2, 2), QuiltedGridTile(1, 1)],
    // Block 3: All small tiles (row of 3)
    [QuiltedGridTile(1, 1), QuiltedGridTile(1, 1), QuiltedGridTile(1, 1)],
  ];

  static List<QuiltedGridTile> generateRandomPattern() {
    final random = Random();
    final List<QuiltedGridTile> pattern = [];

    // Generate a sequence of 20 blocks to ensure enough coverage
    for (int i = 0; i < 20; i++) {
      final blockIndex = random.nextInt(_tileBlocks.length);
      pattern.addAll(_tileBlocks[blockIndex]);
    }
    return pattern;
  }
}
