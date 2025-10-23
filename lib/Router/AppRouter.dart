import 'package:flutter/material.dart';
import 'package:library_app/page/Books/Books_screen.dart';
import 'package:library_app/page/Books/book_detail_screen.dart';
import 'package:library_app/page/History/history_screen.dart';
import 'package:library_app/page/Login_Register_Page/person_info_screen.dart';
import 'package:library_app/page/Login_Register_Page/register_screen.dart';
import 'package:library_app/page/Profile/profile_screen.dart';

import '../page/Books/borrowBook_screen.dart';
import '../page/Books/returnBook_screen.dart';
import '../page/Home_page/home_screen.dart';
import '../page/Login_Register_Page/login_screen.dart';
import 'AppRoutes.dart';
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen(user: {},));

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case AppRoutes.personinfo:
        return MaterialPageRoute(builder: (_) => PersonInfoScreen());

      case AppRoutes.books:
        return MaterialPageRoute(builder: (_) => BooksScreen());

      case AppRoutes.bookDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(/*bookId: args?['bookId']*/),
        );

      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => HistoryScreen());

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());

      case AppRoutes.borrowBook:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BorrowbookScreen(/*bookId: args?['bookId']*/),
        );

      case AppRoutes.returnBook:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ReturnbookScreen(/*bookId: args?['bookId']*/),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Không tìm thấy màn hình: ${settings.name}')),
          ),
        );
    }
  }
}
