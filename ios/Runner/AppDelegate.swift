import UIKit
import Flutter
import UserNotifications            // ← مهم لإشعارات iOS
import flutter_local_notifications  // ← مهم لتهيئة البلجن

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // خلّي مركز الإشعارات يمرّر إشعارات الـ foreground للتطبيق
    UNUserNotificationCenter.current().delegate = self

    // (اختياري) لو بتستخدم scheduling/isolates مع الإشعارات
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
