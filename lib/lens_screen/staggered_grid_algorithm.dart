import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StaggeredGridAlgorithm {
  static const List<QuiltedGridTile> pattern = [
    QuiltedGridTile(2, 2),
    QuiltedGridTile(1, 1),
    QuiltedGridTile(1, 1),
    QuiltedGridTile(1, 1),
    QuiltedGridTile(1, 1),
  ];
  static List<QuiltedGridTile> getPattern() => pattern;

  static bool isBigTile(int index) {
    return (index % 5) == 0;
  }
}
