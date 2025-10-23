import 'package:flutter/material.dart';

import 'Router/AppRouter.dart';
import 'Router/AppRoutes.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Management App',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.login,
      theme: ThemeData(useMaterial3: true),
    );
  }
}
