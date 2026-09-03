import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class KarmaSetuApp extends StatelessWidget {
  const KarmaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KarmaSetu',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
