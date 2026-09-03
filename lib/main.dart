import 'package:flutter/material.dart';
import 'app/routes/app_router.dart';
import 'app/routes/route_names.dart';
import 'app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KarmaSetuApp());
}

class KarmaSetuApp extends StatelessWidget {
  const KarmaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KarmaSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.splash,
      routes: appRoutes,
    );
  }
}
