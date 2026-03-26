import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/api_localhost/AuthService.dart';
import 'package:library_app/api_localhost/BookService.dart';
import 'package:library_app/api_localhost/CategorySevice.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/page/Login_Register_Page/person_info_screen.dart';
import 'package:library_app/page/Login_Register_Page/register_screen.dart';
import '../bloc/auth/bloc.dart';
import '../bloc/category/bloc.dart';
import '../model/user_model.dart';
import '../page/CartReservation/CartReservationScreen.dart';
import '../page/Home/Books/book_detail_screen.dart';
import '../page/Home/home_screen.dart';
import '../page/Login_Register_Page/login_screen.dart';
import 'AppRoutes.dart';
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(user: user),
        );
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case AppRoutes.personinfo:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (_) => PersonInfoScreen(user:user));
      case AppRoutes.bookDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final book = args['book'] as BookModel;
        final user = args['user'] as UserModel;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers:[
              BlocProvider(
                create: (_) => BookBloc(bookService()),
              ),
            ],
            child: BookDetailScreen(bookModel: book, userModel: user,),
          ),
        );
      case AppRoutes.cardRecervation:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (_) => CartReservationScreen(userModel: user,));
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text(
                context.tr(
                  'router.not_found',
                  params: {'route': settings.name ?? ''},
                ),
              ),
            ),
          ),
        );
    }
  }
}
