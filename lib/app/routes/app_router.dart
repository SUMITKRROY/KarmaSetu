import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leave/presentation/pages/leave_requests_page.dart';
import 'route_names.dart';

Map<String, WidgetBuilder> get appRoutes => {
      RouteNames.splash: (context) => const SplashScreen(),
      RouteNames.login: (context) => const LoginPage(),
      RouteNames.dashboard: (context) => const DashboardPage(),
      RouteNames.leaveRequests: (context) => const LeaveRequestsPage(isTab: false),
    };

final appRouter = RouterConfig<Object>(
  routerDelegate: _KarmaRouterDelegate(),
  routeInformationParser: _KarmaRouteInformationParser(),
);

class _KarmaRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri.path;
  }

  @override
  RouteInformation? restoreRouteInformation(Object configuration) {
    return RouteInformation(uri: Uri.parse(configuration.toString()));
  }
}

class _KarmaRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  String _location = RouteNames.splash;

  @override
  Object? get currentConfiguration => _location;

  void navigateTo(String location) {
    _location = location;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_location == RouteNames.dashboard) {
      child = const DashboardPage();
    } else if (_location == RouteNames.login) {
      child = const LoginPage();
    } else if (_location == RouteNames.leaveRequests) {
      child = const LeaveRequestsPage(isTab: false);
    } else {
      child = const SplashScreen();
    }

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: ValueKey(_location),
          child: child,
        ),
      ],
      onDidRemovePage: (page) {
        _location = RouteNames.login;
        notifyListeners();
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {
    _location = configuration.toString();
    notifyListeners();
  }
}
