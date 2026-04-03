import 'package:flutter/material.dart';
import 'package:library_app/model/user_model.dart';
import 'package:library_app/Router/AppRoutes.dart';
import '../responsive_scaffold.dart';
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

  static const _navItems = [
    NavItem(Icons.menu_book_rounded, Icons.menu_book_outlined, 'Книги'),
    NavItem(Icons.swap_horiz_rounded, Icons.swap_horiz_outlined, 'Займы'),
    NavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Отчёты'),
    NavItem(Icons.people_rounded, Icons.people_outline, 'Пользователи'),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xffFF9E74)),
            SizedBox(width: 8),
            Text('Выйти из системы',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
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
        context, AppRoutes.login, (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      tabs: _pages,
      items: _navItems,
      logoText: 'Librarian',
      trailing: IconButton(
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
        tooltip: 'Выйти',
        onPressed: _logout,
        splashRadius: 24,
      ),
    );
  }
}
