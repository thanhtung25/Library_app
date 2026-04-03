import 'package:flutter/material.dart';

/// Responsive shell: sidebar on wide screens, bottom nav on mobile.
///   - compact:  < 600   → BottomNavigationBar
///   - medium:   600-899 → NavigationRail (icons only)
///   - expanded: >= 900  → NavigationRail (extended with labels)
class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> tabs;
  final List<NavItem> items;
  final Widget? trailing;
  final String? logoText;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.tabs,
    required this.items,
    this.trailing,
    this.logoText,
  });

  static const Color _orange = Color(0xffFF9E74);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) {
      return _buildSidebarLayout(context, extended: width >= 900);
    }
    return _buildBottomNavLayout(context);
  }

  Widget _buildSidebarLayout(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            extended: extended,
            minExtendedWidth: 200,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: _orange),
            selectedLabelTextStyle: const TextStyle(
              color: _orange,
              fontWeight: FontWeight.w600,
            ),
            unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
            unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500),
            indicatorColor: _orange.withOpacity(0.12),
            leading: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 20,
                horizontal: extended ? 16 : 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_library_rounded, color: _orange, size: 28),
                  if (extended && logoText != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      logoText!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff3D2314),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: trailing != null
                ? Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: trailing!,
                      ),
                    ),
                  )
                : null,
            destinations: items
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.outlinedIcon),
                      selectedIcon: Icon(item.filledIcon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: tabs[currentIndex]),
        ],
      ),
    );
  }

  Widget _buildBottomNavLayout(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: tabs[currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          elevation: 12,
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ...List.generate(items.length, (i) {
                  final selected = currentIndex == i;
                  return IconButton(
                    icon: Icon(
                      selected ? items[i].filledIcon : items[i].outlinedIcon,
                      color: selected ? _orange : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => onDestinationSelected(i),
                    splashRadius: 26,
                  );
                }),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String label;
  const NavItem(this.filledIcon, this.outlinedIcon, this.label);
}

/// Helper: responsive grid columns based on width.
int responsiveGridColumns(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1200) return 5;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}
