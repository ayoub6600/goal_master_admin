// ignore: avoid_classes_with_only_static_members
class EndPoints {
  //********  base url
  static const String baserUrl = 'http://127.0.0.1:8000/api/';

  //******* routes
  static const String id = 'id'; //! example route, remove this

  //# parent
  static String login = 'login';
  static String saveFcmToken = 'user/save-fcm-token';

  static String banner = "list/slider";

  static String addCustomer = 'manager/customer-create';

  static String sendOTP = 'resend-otp';

  static String verifyOTP = 'verify';
  static String markNotificationAsRead(String notificationId) =>
      'user/notifications/read-notification/$notificationId';

  static String markAllNotificationsAsRead =
      'user/notifications/read-all-notification';

  static String update = 'user/update';

  static String register = 'register';
  static String managerRegister = 'manager/register';
  static String managerPublicPlans = 'manager/public-subscription-plans';
  static String managerSetupBootstrap = 'manager/setup/bootstrap';
  static String managerCreateFirstVenue = 'manager/setup/first-venue';
  static String managerSetupBookingPeriods = 'manager/setup/booking-periods';
  static String managerSetupCatalog = 'manager/setup/catalog';
  static String managerWalletSummary = 'manager/wallet/summary';
  static String managerWalletTransactions = 'manager/wallet/transactions';
  static String managerWalletConfirmTopUp = 'manager/wallet/confirm-topup';
  static String managerWalletLocalPaymentSetting =
      'manager/wallet/local-payment-setting';
  static String managerSubscriptionCurrent = 'manager/subscription/current';
  static String managerSubscriptionChange = 'manager/subscription/change';
  static String managerSubscriptionAutoRenew = 'manager/subscription/auto-renew';
  static String notification = 'user/notifications/get-notification';
  static String deleteAccount = 'user/delete';

  static String getBookingInfo(int id) => 'user/booking/get-info/?id=$id';
  static String changePassword = 'change-password';
  static String getForgivingGenerous(int id) =>
      'user/booking/get-forgiving-generous?page=$id';

  static String changePasswordUser = 'user/change-password-user';

  static String refresh = 'user/refresh';
  static String appVersionCheck = 'app-version/check';

  static String profile = 'user/profile';
  static String analysis = "manager/dashboard/analysis";
  static String bookingHistory(int id) => "user/booking/all?page=$id";

  static String listMonthlyBooking(int id) =>
      'user/booking/getMonthlyBookingList?page=$id';

  static String cancelBooking = 'user/booking/cancel-booking';

  static String listZone = 'list/zone';
  static String listClub = 'list/club';

  static String listCategory = 'list/category';

  static String listService = 'list/service';

  static String listEmployee = 'list/booking';

  static String listTimeslot = 'list/timeslot';

  static String addBooking = 'user/booking/store-booking';

  static String charge = 'user/card/charge';
  //user/card/balance

  static String balance = 'user/card/balance';
  static String listCustomer = "list/customers";
  //user/booking/updateMonthlyBooking

  static String updateMonthlyBooking = 'user/booking/updateMonthlyBooking';

  ///user/booking/fillter-new-booking?page=5

  static String fillterNewBooking(int id) =>
      'user/booking/fillter-new-booking?page=$id';

  static String updateStatusBooking =
      'manager/booking/change-service-booking-status';

  static String depositBookingPayment = 'manager/booking/depoist-money';

  static String getPaidBookings(String type) =>
      'user/booking/get-paid-bookings?type=$type';
  static String getDueBookings = 'user/booking/get-due-bookings';
}

//doctors/top-ratings
