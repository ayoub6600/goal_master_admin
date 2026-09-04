// ignore: avoid_classes_with_only_static_members
class EndPoints {
  //********  base url
  /// Where the API lives, chosen at BUILD time.
  ///
  /// `127.0.0.1` means different things on different devices: the Simulator
  /// borrows the Mac's network stack so loopback reaches `artisan serve`,
  /// while on a real iPhone loopback is the phone itself and every request is
  /// refused. The default keeps the Simulator working untouched; a device
  /// passes the Mac's LAN address instead:
  ///
  ///   flutter run --dart-define=API_BASE=http://192.168.1.x:8000/api/
  ///
  /// Deliberately `String.fromEnvironment`, so this stays a compile-time
  /// constant baked into the binary — a machine-specific address is never
  /// committed, and there is no runtime lookup on every request. Mirrors the
  /// customer app, which reached this shape first.
  static const String baserUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );

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

  /// Every plan with what it means for THIS manager right now — the action to
  /// show on each card, and for an upgrade the figures behind it. The lifecycle
  /// decision and every amount are the server's.
  static String managerSubscriptionOptions = 'manager/subscription/options';

  /// Drop a downgrade or plan switch scheduled for the next cycle.
  static String managerSubscriptionCancelScheduled =
      'manager/subscription/cancel-scheduled-change';
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
  static String pendingExceptions = 'manager/cases/pending-exceptions';
  static String decideException = 'manager/cases/decide-exception';
  static String awaitingAttendance = 'manager/cases/awaiting-attendance';
  static String markAttendance = 'manager/cases/mark-attendance';
  static String proposeNoShowResolution =
      'manager/cases/propose-no-show-resolution';
  static String restrictCustomer = 'manager/cases/restrict-customer';
  static String releaseRestriction = 'manager/cases/release-restriction';
  static String blockCustomer = 'manager/cases/block-customer';
  static String unblockCustomer = 'manager/cases/unblock-customer';
  static String customerBlockStatus = 'manager/cases/customer-block-status';
  static String cancelManagerSeries = 'user/booking/manager-series-cancel';

  static String listZone = 'list/zone';
  static String listClub = 'list/club';

  static String listCategory = 'list/category';

  static String listService = 'list/service';

  static String listEmployee = 'list/booking';

  static String listTimeslot = 'list/timeslot';

  /// One operational night with the internal time bands already merged. The
  /// manager picks a night; the server says which calendar day each slot falls
  /// on. Supersedes [listTimeslot] for the booking flow — that route stays for
  /// builds already in the field.
  static String operationalAvailability = 'list/operational-availability';

  /// Whether the night already in progress still has future slots, and which
  /// night that is. Never computed from the device clock.
  static String operationalNightContext = 'list/operational-night-context';

  static String addBooking = 'user/booking/store-booking';

  /// The four appointments a recurring booking would create, and which of them
  /// are taken. Same endpoint the customer app uses — one recurrence engine.
  static String seriesPreview = 'user/booking/series/preview';

  static String charge = 'user/card/charge';
  //user/card/balance

  static String balance = 'user/card/balance';
  static String listCustomer = "list/customers";

  /// The manager's own customer book: alias-aware, searchable across alias,
  /// platform name and phone, paginated, and reachable before a customer's
  /// first booking.
  static String managerCustomers = "manager/customers";
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

  /// The venue's view of one recurring booking, and the single decision that
  /// covers all of its sessions.
  static String managerSeries(int id) => 'user/booking/manager-series/$id';
  static String managerSeriesDecision = 'user/booking/manager-series-decision';

  /// Calls off the remaining sessions of one recurring booking, in a single
  /// action, through the same service the customer's own "cancel the rest"
  /// uses — so refunds and the ledger behave identically whoever pressed it.
  static String managerSeriesCancel = 'user/booking/manager-series-cancel';
  static String managerSeriesDeposit = 'user/booking/manager-series-deposit';

  /// Editing one existing booking. Used here to move a single session of a
  /// recurring booking without touching the rest of it.
  static String updateBooking = 'user/booking/update-booking';
}

//doctors/top-ratings
