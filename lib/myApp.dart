import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/api_localhost/bookService.dart';
import 'package:library_app/bloc/auth/bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';

import 'Router/AppRouter.dart';
import 'Router/AppRoutes.dart';
import 'api_localhost/AuthService.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();
  final bookService bookservice = bookService();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers:[
        BlocProvider(
          create: (_) => AuthBloc(authService),
        ),
        BlocProvider(
          create: (_) => BookBloc(bookservice),
        ),
      ],
      child: MaterialApp(
        title: 'Library Management App',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRoutes.login,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}
