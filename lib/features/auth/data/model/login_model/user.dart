class User {
  int? id;
  String? name;
  String? username;
  String? phoneNumber;
  int? isSysAdm;
  int? userType;
  dynamic photo;
  dynamic schEmployeeId;
  int? status;
  dynamic email;
  dynamic emailVerifiedAt;
  int? zoneId;
  int? clubId;
  CurrentSubscription? currentSubscription;
  SubscriptionFeatures? subscriptionFeatures;
  ManagerSetupProgress? setupProgress;

  User(
      {this.id,
      this.name,
      this.username,
      this.phoneNumber,
      this.isSysAdm,
      this.userType,
      this.photo,
      this.schEmployeeId,
      this.status,
      this.email,
      this.emailVerifiedAt,
      this.zoneId,
      this.clubId,
      this.currentSubscription,
      this.subscriptionFeatures,
      this.setupProgress});

  @override
  String toString() {
    return 'User(id: $id, name: $name, username: $username, phoneNumber: $phoneNumber, isSysAdm: $isSysAdm, userType: $userType, photo: $photo, schEmployeeId: $schEmployeeId, status: $status, email: $email, emailVerifiedAt: $emailVerifiedAt)';
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int?,
        name: json['name'] as String?,
        username: json['username'] as String?,
        phoneNumber: json['phone_number'] as String?,
        isSysAdm: json['is_sys_adm'] as int?,
        userType: json['user_type'] as int?,
        photo: json['photo'] as dynamic,
        schEmployeeId: json['sch_employee_id'] as dynamic,
        status: json['status'] as int?,
        email: json['email'] as dynamic,
        emailVerifiedAt: json['email_verified_at'] as dynamic,
        zoneId: json['zone_id'] as int?,
        clubId: json['club_id'] as int?,
        currentSubscription: json['current_subscription'] == null
            ? null
            : CurrentSubscription.fromJson(
                json['current_subscription'] as Map<String, dynamic>,
              ),
        subscriptionFeatures: json['subscription_features'] == null
            ? null
            : SubscriptionFeatures.fromJson(
                json['subscription_features'] as Map<String, dynamic>,
              ),
        setupProgress: json['setup_progress'] == null
            ? null
            : ManagerSetupProgress.fromJson(
                json['setup_progress'] as Map<String, dynamic>,
              ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'phone_number': phoneNumber,
        'is_sys_adm': isSysAdm,
        'user_type': userType,
        'photo': photo,
        'sch_employee_id': schEmployeeId,
        'status': status,
        'email': email,
        'email_verified_at': emailVerifiedAt,
        'zone_id': zoneId,
        'club_id': clubId,
        'current_subscription': currentSubscription?.toJson(),
        'subscription_features': subscriptionFeatures?.toJson(),
        'setup_progress': setupProgress?.toJson(),
      };

  bool get canUseMonthlyBookings =>
      subscriptionFeatures?.allowMonthlyBookings ?? true;

  bool get canUseReports => subscriptionFeatures?.allowReports ?? true;

  bool get canUseWebAccess => subscriptionFeatures?.allowWebAccess ?? true;

  bool get hasCompletedVenueSetup =>
      setupProgress?.canStartBooking ??
      ((zoneId ?? 0) > 0 && (clubId ?? 0) > 0);

  bool get needsVenueSetup =>
      !(setupProgress?.canStartBooking ?? hasCompletedVenueSetup);

  String get nextSetupStepLabel =>
      setupProgress?.nextStepLabel ?? 'إكمال إعداد بيانات الملعب';

  bool get hasBranchProfile => setupProgress?.hasBranch ?? ((clubId ?? 0) > 0);

  bool get canStartManagerBookings =>
      setupProgress?.canStartBooking ?? hasCompletedVenueSetup;

  String get subscriptionStatus =>
      currentSubscription?.status?.toLowerCase().trim() ?? '';

  bool get isTrialingSubscription => subscriptionStatus == 'trialing';

  bool get isActivePaidSubscription => subscriptionStatus == 'active';

  bool get needsSubscriptionPaymentNow =>
      subscriptionStatus == 'paused' ||
      subscriptionStatus == 'cancelled' ||
      subscriptionStatus == 'expired';
}

class CurrentSubscription {
  final int? id;
  final String? planName;
  final String? planCode;
  final String? status;
  final String? billingCycle;
  final String? startsAt;
  final String? endsAt;
  final String? trialEndsAt;

  CurrentSubscription({
    this.id,
    this.planName,
    this.planCode,
    this.status,
    this.billingCycle,
    this.startsAt,
    this.endsAt,
    this.trialEndsAt,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) {
    return CurrentSubscription(
      id: _toInt(json['id']),
      planName: json['plan_name']?.toString(),
      planCode: json['plan_code']?.toString(),
      status: json['status']?.toString(),
      billingCycle: json['billing_cycle']?.toString(),
      startsAt: json['starts_at']?.toString(),
      endsAt: json['ends_at']?.toString(),
      trialEndsAt: json['trial_ends_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_name': planName,
        'plan_code': planCode,
        'status': status,
        'billing_cycle': billingCycle,
        'starts_at': startsAt,
        'ends_at': endsAt,
        'trial_ends_at': trialEndsAt,
      };

  int? get daysRemaining {
    if (endsAt == null || endsAt!.isEmpty) return null;
    final end = DateTime.tryParse(endsAt!);
    if (end == null) return null;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return end.difference(startOfToday).inDays;
  }

  bool get isExpiringSoon {
    final remaining = daysRemaining;
    return remaining != null && remaining <= 7;
  }

  bool get isExpired {
    final remaining = daysRemaining;
    return remaining != null && remaining < 0;
  }

  bool get isTrial => status?.toLowerCase().trim() == 'trialing';
}

class SubscriptionFeatures {
  final int maxBranches;
  final int maxFields;
  final int maxStaff;
  final bool allowOnlinePayments;
  final bool allowLocalPayment;
  final bool allowWallet;
  final bool allowMonthlyBookings;
  final bool allowReports;
  final bool allowWebAccess;
  final bool allowCustomerSupportTools;

  SubscriptionFeatures({
    required this.maxBranches,
    required this.maxFields,
    required this.maxStaff,
    required this.allowOnlinePayments,
    required this.allowLocalPayment,
    required this.allowWallet,
    required this.allowMonthlyBookings,
    required this.allowReports,
    required this.allowWebAccess,
    required this.allowCustomerSupportTools,
  });

  factory SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeatures(
      maxBranches: _toInt(json['max_branches']),
      maxFields: _toInt(json['max_fields']),
      maxStaff: _toInt(json['max_staff']),
      allowOnlinePayments: _toBool(json['allow_online_payments']),
      allowLocalPayment: _toBool(json['allow_local_payment']),
      allowWallet: _toBool(json['allow_wallet']),
      allowMonthlyBookings: _toBool(json['allow_monthly_bookings']),
      allowReports: _toBool(json['allow_reports']),
      allowWebAccess: _toBool(json['allow_web_access']),
      allowCustomerSupportTools: _toBool(json['allow_customer_support_tools']),
    );
  }

  Map<String, dynamic> toJson() => {
        'max_branches': maxBranches,
        'max_fields': maxFields,
        'max_staff': maxStaff,
        'allow_online_payments': allowOnlinePayments,
        'allow_local_payment': allowLocalPayment,
        'allow_wallet': allowWallet,
        'allow_monthly_bookings': allowMonthlyBookings,
        'allow_reports': allowReports,
        'allow_web_access': allowWebAccess,
        'allow_customer_support_tools': allowCustomerSupportTools,
      };
}

class ManagerSetupProgress {
  final bool hasBranch;
  final bool hasCategory;
  final bool hasService;
  final bool hasEmployee;
  final bool canStartBooking;
  final String nextStepKey;
  final String nextStepLabel;

  const ManagerSetupProgress({
    required this.hasBranch,
    required this.hasCategory,
    required this.hasService,
    required this.hasEmployee,
    required this.canStartBooking,
    required this.nextStepKey,
    required this.nextStepLabel,
  });

  factory ManagerSetupProgress.fromJson(Map<String, dynamic> json) {
    return ManagerSetupProgress(
      hasBranch: _toBool(json['has_branch']),
      hasCategory: _toBool(json['has_category']),
      hasService: _toBool(json['has_service']),
      hasEmployee: _toBool(json['has_employee']),
      canStartBooking: _toBool(json['can_start_booking']),
      nextStepKey: json['next_step_key']?.toString() ?? '',
      nextStepLabel: json['next_step_label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'has_branch': hasBranch,
        'has_category': hasCategory,
        'has_service': hasService,
        'has_employee': hasEmployee,
        'can_start_booking': canStartBooking,
        'next_step_key': nextStepKey,
        'next_step_label': nextStepLabel,
      };
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  return value?.toString() == '1' || value?.toString().toLowerCase() == 'true';
}

class UserData {
  final User? user;
  final String? token;

  UserData({this.user, this.token});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : null,
      token: json['token'] as String?,
    );
  }
}

class UpdateProfileResponse {
  final String? status;
  final UserData? data;
  final String? message;

  UpdateProfileResponse({this.status, this.data, this.message});

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      status: json['status'],
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}
