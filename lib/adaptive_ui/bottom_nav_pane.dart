import 'package:flutter/material.dart';

class BottomNavPane extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const BottomNavPane({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _BottomNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      _BottomNavItem(
        icon: Icons.chat_outlined,
        selectedIcon: Icons.chat,
        label: 'Chats',
      ),
      _BottomNavItem(
        icon: Icons.search,
        selectedIcon: Icons.search,
        label: 'Search',
      ),
      _BottomNavItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Community',
      ),
      _BottomNavItem(
        icon: Icons.camera_alt_outlined,
        selectedIcon: Icons.camera_alt,
        label: 'Lens',
      ),
    ];

    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          return Stack(
            children: [
              // Animated Bubble Background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutBack,
                left: selectedIndex * itemWidth + 8,
                top: 12,
                width: itemWidth - 16,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Items Row
              Row(
                children: List.generate(items.length, (index) {
                  final isSelected = selectedIndex == index;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDestinationSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: isSelected
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.label,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
