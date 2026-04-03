import 'package:flutter/material.dart';

import '../../model/user_model.dart';
import '../responsive_scaffold.dart';
import 'Books/Books_screen.dart';
import 'Borrow/borrowBook_screen.dart';
import 'Favorite/favorite_screen.dart';
import 'HomeTab.dart';
import 'Profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({required this.user, super.key});
  @override
  State<HomeScreen> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<HomeScreen> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  static const _navItems = [
    NavItem(Icons.home_rounded, Icons.home_outlined, 'Главная'),
    NavItem(Icons.menu_book_rounded, Icons.menu_book_outlined, 'Книги'),
    NavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Займ'),
    NavItem(Icons.favorite_rounded, Icons.favorite_outline, 'Избранные'),
    NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(user: widget.user, onChangeTab: onTabTapped),
      BooksScreen(user: widget.user),
      BorrowbookScreen(user: widget.user),
      FavoriteScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: onTabTapped,
      tabs: tabs,
      items: _navItems,
      logoText: 'Library',
    );
  }
}
