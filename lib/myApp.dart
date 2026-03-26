import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:library_app/api_localhost/BookService.dart';
import 'package:library_app/api_localhost/CategorySevice.dart';
import 'package:library_app/bloc/auth/bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/category/bloc.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/localization/locale_controller.dart';

import 'Router/AppRouter.dart';
import 'Router/AppRoutes.dart';
import 'api_localhost/AuthService.dart';
import 'api_localhost/reservation_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();
  final bookService bookservice = bookService();
  final CategoryService categoryService = CategoryService();
  final ReservationService reservationService = ReservationService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MultiBlocProvider(
          providers:[
            BlocProvider(
              create: (_) => AuthBloc(authService),
            ),
            BlocProvider(
              create: (_) => BookBloc(bookservice),
            ),
            BlocProvider(
              create: (_) => CategoryBloc(categoryService),
            ),
            BlocProvider(
              create: (_) => ReservationBloc(reservationService),
            ),
          ],
          child: MaterialApp(
            title: 'Library Management App',
            debugShowCheckedModeBanner: false,
            locale: localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRoutes.login,
            theme: ThemeData(useMaterial3: true),
          ),
        );
      },
    );
  }
}
