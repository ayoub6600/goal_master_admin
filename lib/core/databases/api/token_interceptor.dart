import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/app_router.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';

import 'package:goal_master_admin/features/auth/data/repo/auth_repo_imp.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  TokenInterceptor(this.dio);

  static bool _redirecting = false;

  /// The session is over (expired, or ended by a password change or account
  /// deletion elsewhere): clear it and go to the login screen once. It used
  /// to clear the session and stay put, so every screen just kept failing.
  Future<void> _redirectToLogin() async {
    if (_redirecting) return;
    _redirecting = true;
    try {
      await SharedPreferenceUtil.clear();
      // نحتفظ بـ onboardingSeen = true حتى لا يعود للـ onboarding
      await SharedPreferenceUtil.putBool(PrefKey.onboardingSeen, true);
      await SharedPreferenceUtil.putString(PrefKey.login, "false");
      if (AppRouter.hasRouter) AppRouter.router.go(RoutesKeys.kLogin);
    } finally {
      _redirecting = false;
    }
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final body = err.response?.data;
    if (err.response?.statusCode == 401 &&
        body is Map &&
        body['reason'] == 'session_revoked') {
      await _redirectToLogin();
      handler.next(err);
      return;
    }

    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains("profile") &&
        !_isRefreshing) {
      _isRefreshing = true;

      final result = await GetIt.I<AuthRepoImpl>().profile();

      await result.fold(
        (failure) async {
          _isRefreshing = false;
          await _redirectToLogin(); // ✅ التحويل إلى login
          handler.reject(err);
        },
        (newToken) async {
          await SharedPreferenceUtil.putString(PrefKey.fcmToken, newToken);

          final opts = err.requestOptions;
          opts.headers["Authorization"] = "Bearer $newToken";

          try {
            final cloneReq = await dio.fetch(opts);
            _isRefreshing = false;
            handler.resolve(cloneReq);
          } catch (e) {
            _isRefreshing = false;
            await _redirectToLogin(); // لو فشل بعد التحديث برضو نحوله
            handler.reject(err);
          }
        },
      );
    } else {
      handler.next(err);
    }
  }
}
