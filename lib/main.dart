import 'package:flutter/material.dart';
import 'app/app_widget.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const AppWidget());
}
