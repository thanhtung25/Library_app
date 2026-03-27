import 'package:flutter/material.dart';
import 'package:library_app/model/user_model.dart';
import 'BookList/Booklistscreen.dart';
import 'LoanManagement/Loanmanagementscreen.dart';
import 'Report/Reportscreen.dart';
import 'UserManagement/Usermanagementscreen.dart';

class LibrarianShell extends StatefulWidget {
  final UserModel user;
  const LibrarianShell({super.key, required this.user});

  @override
  State<LibrarianShell> createState() => _LibrarianShellState();
}

class _LibrarianShellState extends State<LibrarianShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BookListScreen(user: widget.user),
      LoanManagementScreen(user: widget.user),
      ReportScreen(user: widget.user),
      UserManagementScreen(user: widget.user),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          elevation: 12,
          color: Colors.white,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarIcon(
                  icon: Icons.menu_book_rounded,
                  selected: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavBarIcon(
                  icon: Icons.swap_horiz_rounded,
                  selected: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavBarIcon(
                  icon: Icons.bar_chart_rounded,
                  selected: _currentIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                _NavBarIcon(
                  icon: Icons.people_rounded,
                  selected: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: selected ? const Color(0xffFF9E74) : Colors.grey,
        size: 28,
      ),
      onPressed: onTap,
      splashRadius: 26,
    );
  }
}