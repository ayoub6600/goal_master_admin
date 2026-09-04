class PrefKey {
  static const String baseUrl = "baseUrl";
  static const String login = "LOGIN";
  static const String fcmToken = "FCMTOKEN";
  static const String userId = "USERID";
  static const String isLoggedIn = "IsLoggedIn";
  static const String profileImage = "PROFILE_IMAGE";
  static const String fullName = 'fullName';
  static const String email = "EMAIL";
  static const String country = "COUNTRY";
  static const String mobile = "MOBILE";
  static const String gender = "gender";
  static const String phone = "phone";
  static const String userid = "userid";

  static const String currentLanguageCode = "currentLanguageCode";
  static const String chucker = "chucker";
  static const String homeDialog = "homeDialog";
  static String onboardingSeen = "onboardingSeen";
  static const String refreshToken = "refreshToken";
  static const String zoneId = "zoneId";
  static const String clubId = "clubId";
  static const String subscriptionPlanName = "subscriptionPlanName";
  static const String subscriptionPlanCode = "subscriptionPlanCode";
  static const String subscriptionAllowMonthlyBookings =
      "subscriptionAllowMonthlyBookings";
  static const String subscriptionAllowReports = "subscriptionAllowReports";
  static const String subscriptionAllowWebAccess = "subscriptionAllowWebAccess";

  /// The backend id of the last notification actually shown to the user
  /// (system tray + sound). Persisted so a socket reconnect or app restart
  /// cannot redisplay the same one as though it just arrived.
  static const String lastShownNotificationId = "lastShownNotificationId";
}
