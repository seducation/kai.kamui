import 'package:flutter/material.dart';
import 'nav_rail_sidebar.dart';
import 'bottom_nav_pane.dart';
import 'extra_info_pane.dart';
import 'master_list_pane.dart';

/// A robust adaptive shell for the application.
class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> screens;
  final String title;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.screens,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoints optimized for Mobile, Tablet, and Desktop
        if (constraints.maxWidth < 600) {
          return _buildMobile(context);
        } else if (constraints.maxWidth < 1100) {
          // Tablet / Medium Screen
          return _buildTablet(context);
        } else {
          // Desktop / Large Screen
          return _buildLarge(context);
        }
      },
    );
  }

  /// 1. Mobile (< 600px): BottomNav + Single Screen
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavPane(
        selectedIndex: selectedIndex,
        onDestinationSelected: onIndexChanged,
      ),
    );
  }

  /// 2. Tablet / Medium (600px - 1100px): NavRail + Two Panes
  Widget _buildTablet(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavRailSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onIndexChanged,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Pane 1: Master List (Left Screen)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                AppBar(elevation: 0, title: const Text('Activity')),
                Expanded(
                  child: MasterListPane(
                    items: List.generate(20, (i) => 'Item ${i + 1}'),
                    selectedId: 0,
                    onItemSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Pane 2: Primary Content (Main Screen)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                AppBar(elevation: 0, title: Text(title)),
                Expanded(child: screens[selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Large Screens (> 1100px): NavRail + Three Panes (Stable Layout)
  Widget _buildLarge(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavRailSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onIndexChanged,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Pane 1: Master List (Left Screen - Consistent with Tablet)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                AppBar(elevation: 0, title: const Text('Activity')),
                Expanded(
                  child: MasterListPane(
                    items: List.generate(20, (i) => 'Item ${i + 1}'),
                    selectedId: 0,
                    onItemSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Pane 2: Primary Content (Main Screen)
          Expanded(
            flex: 5,
            child: Column(
              children: [
                AppBar(elevation: 0, title: Text(title)),
                Expanded(child: screens[selectedIndex]),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Pane 3: Analytic/Extra Info (Right Screen)
          const Expanded(flex: 3, child: ExtraInfoPane()),
        ],
      ),
    );
  }
}
