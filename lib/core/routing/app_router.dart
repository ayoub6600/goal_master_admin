import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart'
    show RoutesKeys;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> parentKey = GlobalKey<NavigatorState>();
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
    return parentKey.currentState?.pop(popValue);
  }
}

abstract class AppRouter {
  static final router = GoRouter(
    observers: [ChuckerFlutter.navigatorObserver],
    navigatorKey: parentKey,
    routes: appRoutes,
    initialLocation: RoutesKeys.kLogin,
    // redirect: (context, state) async {
    //   // إزالة السبيلاش بعد تحميل SharedPreferences
    //   FlutterNativeSplash.remove();

    //   // جلب حالة تسجيل الدخول من SharedPreferences
    //   final result = SharedPreferenceUtil.getString(PrefKey.login);

    //   // طباعة نتيجة الحالة (لأغراض التتبع)
    //   print("SharedPref login result: $result");

    //   // التوجيه حسب الحالة
    //   if (result.isEmpty) {
    //     return RoutesKeys.kOnboarding;
    //   } else if (result == 'true') {
    //     return RoutesKeys.kHome;
    //   } else {
    //     return RoutesKeys.kLogin;
    //   }
    // },
  );
}
