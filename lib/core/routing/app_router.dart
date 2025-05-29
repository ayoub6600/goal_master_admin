import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/routes.dart';

import 'package:goal_master_admin/core/routing/routes_keys.dart';

// final GlobalKey<NavigatorState> parentKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>();

extension GoRouterExtension on GoRouter {
  // Navigate back to a specific route
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
    return AppRouter.parentKey.currentState?.pop(popValue);
  }
}

// ignore: avoid_classes_with_only_static_members
abstract class AppRouter {
  static final GlobalKey<NavigatorState> parentKey =
      GlobalKey<NavigatorState>();
  static final AuthNotifier authNotifier = AuthNotifier();

  static final router = GoRouter(
    navigatorKey: parentKey,
    observers: [ChuckerFlutter.navigatorObserver],
    routes: appRoutes,
    refreshListenable: authNotifier, // ✅ أضف هذا
    initialLocation: RoutesKeys.kLogin,
    redirect: (context, state) {
      final result = SharedPreferenceUtil.getString(PrefKey.login);
      final onboardingSeen =
          SharedPreferenceUtil.getBool(PrefKey.onboardingSeen);

      if (!onboardingSeen) {
        return RoutesKeys.kOnboarding;
      }

      if (result == 'true') {
        return RoutesKeys.kHome;
      } else {
        return RoutesKeys.kLogin;
      }
    },
  );
}

class AuthNotifier extends ChangeNotifier {
  bool get isLoggedIn =>
      SharedPreferenceUtil.getString(PrefKey.login) == 'true';

  bool get onboardingSeen =>
      SharedPreferenceUtil.getBool(PrefKey.onboardingSeen);

  void refresh() {
    notifyListeners();
  }
}
