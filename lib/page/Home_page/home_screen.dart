import 'dart:ui';

import 'package:flutter/material.dart';
import '../Login_Register_Page/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
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
      HomeTab(user: widget.user),
      BookTab(),
      RequestTab(),
      SavedTab(),
      ManageTab(),
      ProfileTab(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), // Bạn có thể chỉnh thông số mờ
          child: Container(
            color: Colors.white.withOpacity(0.18), // Nên để màu trắng nhạt, opacity nhỏ
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: Color(0xffFF9E74),
              unselectedItemColor: Colors.grey,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: List.generate(6, (i) {
                final icons = [
                  Icons.home_rounded,
                  Icons.book_rounded,
                  Icons.note_alt_rounded,
                  Icons.bookmark_rounded,
                  Icons.admin_panel_settings_rounded,
                  Icons.person_rounded,
                ];
                final isSelected = i == _currentIndex;
                return BottomNavigationBarItem(
                  icon: AnimatedPadding(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.only(bottom: isSelected ? 14 : 8),
                    child: AnimatedScale(
                      scale: isSelected ? 1.3 : 1.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xffFF715D).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Icon(icons[i], size: 30),
                        ],
                      ),
                    ),
                  ),
                  label: '',
                );
              }),
            ),
          ),
        ),
      ),

    );
  }
}
class HomeTab extends StatelessWidget {
  final Map<String, dynamic> user;
  const HomeTab({required this.user, super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.lightBlue.shade50, // màu nền nhẹ nhàng
    child: Center(
      child: Text(
        'Thông tin nổi bật cho ${user['full_name']}',
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}

class BookTab extends StatelessWidget {
  const BookTab({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.orange.shade50,
    child: Center(
      child: Text(
        'Danh sách sách, phân loại, trạng thái',
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}

class RequestTab extends StatelessWidget {
  const RequestTab({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.green.shade50,
    child: Center(
      child: Text(
        'Yêu cầu mượn sách, lịch sử, thanh toán nợ',
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}

class SavedTab extends StatelessWidget {
  const SavedTab({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.purple.shade50,
    child: Center(
      child: Text(
        'Sách online đã lưu và đánh dấu',
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}

class ManageTab extends StatelessWidget {
  const ManageTab({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.red.shade50,
    child: Center(
      child: Text(
        'Quản lý sách, duyệt, cảnh báo, tài khoản',
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}

class ProfileTab extends StatelessWidget {
  final Map<String, dynamic> user;
  const ProfileTab({required this.user, super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.teal.shade50,
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Tên: ${user['full_name']}'),
        Text('Email: ${user['email']}'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          },
          child: const Text('Đăng xuất'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    ),
  );
}

