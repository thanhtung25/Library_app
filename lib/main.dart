import 'package:flutter/material.dart';
import 'package:library_app/localization/locale_controller.dart';
import 'package:library_app/myApp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localeController.loadSavedLocale();
  runApp(const MyApp());
}
