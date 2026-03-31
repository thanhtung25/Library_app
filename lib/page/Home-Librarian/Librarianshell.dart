import 'package:flutter/material.dart';
import 'package:library_app/model/user_model.dart';
import 'package:library_app/Router/AppRoutes.dart';
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
  static const _orange = Color(0xffFF9E74);
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xffFF9E74)),
            SizedBox(width: 8),
            Text(
              'Выйти из системы',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF9E74),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (route) => false,
      );
    }
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
              children: [
                // ── 4 nav tabs ─────────────────────────────────────
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavBarIcon(
                        icon: Icons.menu_book_rounded,
                        selected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavBarIcon(
                        icon: Icons.swap_horiz_rounded,
                        selected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavBarIcon(
                        icon: Icons.bar_chart_rounded,
                        selected: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _NavBarIcon(
                        icon: Icons.people_rounded,
                        selected: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                    ],
                  ),
                ),

                // ── Divider ─────────────────────────────────────────
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.grey.shade200,
                ),

                // ── Logout button ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent, size: 26),
                    tooltip: 'Выйти',
                    onPressed: _logout,
                    splashRadius: 24,
                  ),
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
