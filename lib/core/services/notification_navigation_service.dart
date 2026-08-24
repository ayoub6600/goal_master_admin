import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:goal_master_admin/core/routing/app_router.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';

/// Navigates to a booking's details screen from a push notification's tap
/// (opened from background) or launch (opened from terminated), using the
/// `booking_id` the backend already attaches to the notification's data
/// payload (see `SendPushNotification()` in goal-master-web).
class NotificationNavigationService {
  static void handleMessageTap(RemoteMessage message) {
    final bookingIdStr = message.data['booking_id'];
    if (bookingIdStr == null) return;

    final bookingId = int.tryParse(bookingIdStr.toString());
    if (bookingId == null) return;

    AppRouter.router.push(RoutesKeys.kBookingItemsDetails, extra: bookingId);
  }

  /// Call once at startup to handle a notification tap that launched the
  /// app from a fully terminated state. `AppRouter.router` isn't created
  /// until `AppStartCubit` resolves its initial route (a real async gap,
  /// since it's built lazily inside `MyApp.build()`), so this polls briefly
  /// for it instead of assuming it already exists.
  static Future<void> handleInitialMessage() async {
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage == null) return;

    for (var i = 0; i < 20; i++) {
      if (AppRouter.hasRouter) {
        handleMessageTap(initialMessage);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}
