import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_app/page/Home/Books/Books_screen.dart';
import 'package:library_app/page/Home/Books/borrowBook_screen.dart';
import 'package:library_app/page/Home/Favorite/favorite_screen.dart';
import 'package:library_app/page/Home/HomeTab.dart';
import 'package:library_app/page/Home/Profile/profile_screen.dart';

import '../../model/user_model.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({required this.user, super.key});
  @override
  State<HomeScreen> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(user: widget.user,onChangeTab: onTabTapped,),
      BooksScreen(user: widget.user),
      BorrowbookScreen(user: widget.user),
      FavoriteScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Để fab và bar nổi lên trên nền page
      body: _tabs.elementAt(_currentIndex),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          elevation: 12,
          color:  Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _NavBarIcon(
                  icon: Icons.home,
                  selected: _currentIndex == 0,
                  onTap: () => onTabTapped(0),
                ),
                _NavBarIcon(
                  icon: Icons.menu_book_outlined,
                  selected: _currentIndex == 1,
                  onTap: () => onTabTapped(1),
                ),
                _NavBarIcon(
                  icon: Icons.calendar_month,
                  selected: _currentIndex == 2,
                  onTap: () => onTabTapped(2),
                ), // Chỗ trống cho FAB ở giữa
                _NavBarIcon(
                  icon: Icons.favorite,
                  selected: _currentIndex == 3,
                  onTap: () => onTabTapped(3),
                ),
                _NavBarIcon(
                  icon: Icons.settings,
                  selected: _currentIndex == 4,
                  onTap: () => onTabTapped(4),
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
  const _NavBarIcon(
      {required this.icon, required this.selected, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: selected ? Color(0xffFF9E74) : Colors.grey, size: 28),
      onPressed: onTap,
      splashRadius: 26,
    );
  }
}










