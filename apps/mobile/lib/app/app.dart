import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/controllers/login_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';

class EventCareApp extends StatelessWidget {
  const EventCareApp({required this.loginController, super.key});

  final LoginController loginController;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PROWEM Event Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: LoginPage(controller: loginController),
      );
}
