import 'package:flutter/material.dart';

import '../features/tournament/presentation/tournament_screen.dart';
import 'app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROWEM Live Score',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const TournamentScreen(),
    );
  }
}
