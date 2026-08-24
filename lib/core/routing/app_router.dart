import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/routing/routes.dart';

final GlobalKey<NavigatorState> parentKey = GlobalKey<NavigatorState>();

extension GoRouterExtension on GoRouter {
  void popUntilPath(BuildContext context, String ancestorPath) {
    while (routerDelegate.currentConfiguration.matches.last.matchedLocation !=
        ancestorPath) {
      if (!context.canPop()) {
        return;
      }
      context.pop();
    }
  }

  static dynamic back([dynamic popValue]) {
    return parentKey.currentState?.pop(popValue);
  }
}

abstract class AppRouter {
  static GoRouter? _router;

  /// The most recently created router — usable for imperative navigation
  /// (e.g. from a push-notification tap handler) where no BuildContext is
  /// available to call `GoRouter.of(context)`.
  static GoRouter get router => _router!;
  static bool get hasRouter => _router != null;

  static GoRouter createRouter(String initialRoute) {
    return _router = GoRouter(
      navigatorKey: parentKey,
      observers: [ChuckerFlutter.navigatorObserver],
      routes: appRoutes,
      initialLocation: initialRoute,
    );
  }
}
