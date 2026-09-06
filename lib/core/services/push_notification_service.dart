import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/databases/api/dio_consumer.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';

// Required by firebase_messaging: must be a top-level (or static) function
// so it can run in its own isolate when the app is backgrounded/terminated.
// It's intentionally a no-op — the OS already renders the notification from
// the message's `notification` payload without any app code running.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  /// Call once, right after Firebase.initializeApp().
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  }

  /// Call after login (or on app start if already logged in) — the backend
  /// route this hits requires an authenticated user.
  ///
  /// Best-effort end to end, deliberately: on iOS, `getToken()` needs an
  /// APNS token first, which may genuinely not exist yet (Simulator,
  /// permission not granted, or a fresh install still registering with
  /// APNs) and throws `FirebaseException(apns-token-not-set)` when it
  /// doesn't. Login must never depend on push registration succeeding —
  /// `onTokenRefresh` (see initialize()) retries this the moment a token
  /// does become available.
  static Future<void> registerTokenIfLoggedIn() async {
    final loggedIn = SharedPreferenceUtil.getString(PrefKey.login) == 'true';
    if (!loggedIn) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (_) {
      // Best-effort — retried on next app open or token refresh.
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      await getIt<DioConsumer>().post(
        EndPoints.saveFcmToken,
        data: {
          'fcm_token': token,
          // Lets the backend keep this device's token in its own row,
          // separate from whatever the Customer App registered for the
          // same person — see user_device_tokens / SendPushNotification().
          'app_domain': 'manager',
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (_) {
      // Best-effort — retried on next app open or token refresh.
    }
  }

  /// Call right before clearing the local session on logout — removes only
  /// THIS device's Manager-app registration, not every token this person
  /// has (e.g. their Customer App on another device keeps working).
  static Future<void> unregisterToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await getIt<DioConsumer>().post(
        EndPoints.logout,
        data: {'fcm_token': token},
      );
    } catch (_) {
      // Best-effort — a missed removal just means one stale token to be
      // cleaned up server-side the next time Firebase reports it invalid.
    }
  }
}
