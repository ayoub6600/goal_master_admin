class ManagerWalletResponse {
  final bool success;
  final WalletData data;

  const ManagerWalletResponse({
    required this.success,
    required this.data,
  });

  factory ManagerWalletResponse.fromJson(Map<String, dynamic> json) {
    return ManagerWalletResponse(
      success: _toBool(json['status']),
      data: WalletData.fromJson(
        json['data'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class WalletData {
  final WalletSummaryData wallet;
  final WalletSubscriptionData subscription;
  final WalletLocalPaymentData localPayment;
  final WalletTransactionsData? transactions;

  const WalletData({
    required this.wallet,
    required this.subscription,
    required this.localPayment,
    this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      wallet: WalletSummaryData.fromJson(
        json['wallet'] as Map<String, dynamic>? ?? const {},
      ),
      subscription: WalletSubscriptionData.fromJson(
        json['subscription'] as Map<String, dynamic>? ?? const {},
      ),
      localPayment: WalletLocalPaymentData.fromJson(
        json['local_payment'] as Map<String, dynamic>? ?? const {},
      ),
      transactions: json['transactions'] == null
          ? null
          : WalletTransactionsData.fromJson(
              json['transactions'] as Map<String, dynamic>,
            ),
    );
  }

  WalletData copyWith({
    WalletSummaryData? wallet,
    WalletSubscriptionData? subscription,
    WalletLocalPaymentData? localPayment,
    WalletTransactionsData? transactions,
  }) {
    return WalletData(
      wallet: wallet ?? this.wallet,
      subscription: subscription ?? this.subscription,
      localPayment: localPayment ?? this.localPayment,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletSummaryData {
  final double currentBalance;
  final int transactionsCount;
  final List<WalletTransactionItem> recentTransactions;

  /// Money customers have already paid for sessions not yet played.
  final WalletHeldData held;

  const WalletSummaryData({
    required this.currentBalance,
    required this.transactionsCount,
    required this.recentTransactions,
    this.held = const WalletHeldData(),
  });

  factory WalletSummaryData.fromJson(Map<String, dynamic> json) {
    return WalletSummaryData(
      held: WalletHeldData.fromJson(
        json['held'] as Map<String, dynamic>? ?? const {},
      ),
      currentBalance: _toDouble(json['current_balance']),
      transactionsCount: _toInt(json['transactions_count']),
      recentTransactions: (json['recent_transactions'] as List<dynamic>? ?? [])
          .map(
            (item) => WalletTransactionItem.fromJson(
              item as Map<String, dynamic>? ?? const {},
            ),
          )
          .toList(),
    );
  }
}

/// Funds held by the platform on the venue's behalf.
///
/// A monthly booking is paid in full up front, but the venue is paid one
/// session at a time as each is played — so a cancelled session is refunded
/// out of money still held, never clawed back from a manager who may already
/// have spent it. Shown because four booked sessions and an unchanged balance
/// otherwise look like a payment that went missing.
class WalletHeldData {
  final double amount;
  final int seriesCount;
  final int sessionsPending;
  final String note;

  const WalletHeldData({
    this.amount = 0,
    this.seriesCount = 0,
    this.sessionsPending = 0,
    this.note = '',
  });

  bool get hasHeldFunds => amount > 0;

  factory WalletHeldData.fromJson(Map<String, dynamic> json) {
    return WalletHeldData(
      amount: _toDouble(json['amount']),
      seriesCount: _toInt(json['series_count']),
      sessionsPending: _toInt(json['sessions_pending']),
      note: json['note']?.toString() ?? '',
    );
  }
}

class WalletSubscriptionData {
  final String planName;
  final String billingCycle;
  final String trialEndsAt;
  final bool isTrialActive;
  final bool requiresPaymentNow;

  const WalletSubscriptionData({
    required this.planName,
    required this.billingCycle,
    required this.trialEndsAt,
    required this.isTrialActive,
    required this.requiresPaymentNow,
  });

  factory WalletSubscriptionData.fromJson(Map<String, dynamic> json) {
    return WalletSubscriptionData(
      planName: json['plan_name']?.toString() ?? '',
      billingCycle: json['billing_cycle']?.toString() ?? '',
      trialEndsAt: json['trial_ends_at']?.toString() ?? '',
      isTrialActive: _toBool(json['is_trial_active']),
      requiresPaymentNow: _toBool(json['requires_payment_now']),
    );
  }
}

class WalletLocalPaymentData {
  final bool subscriptionAllowsLocalPayment;
  final bool enabledForBranch;
  final int branchId;
  final String branchName;

  const WalletLocalPaymentData({
    required this.subscriptionAllowsLocalPayment,
    required this.enabledForBranch,
    required this.branchId,
    required this.branchName,
  });

  factory WalletLocalPaymentData.fromJson(Map<String, dynamic> json) {
    return WalletLocalPaymentData(
      subscriptionAllowsLocalPayment:
          _toBool(json['subscription_allows_local_payment']),
      enabledForBranch: _toBool(json['enabled_for_branch']),
      branchId: _toInt(json['branch_id']),
      branchName: json['branch_name']?.toString() ?? '',
    );
  }
}

class WalletTransactionsData {
  final List<WalletTransactionItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const WalletTransactionsData({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory WalletTransactionsData.fromJson(Map<String, dynamic> json) {
    return WalletTransactionsData(
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => WalletTransactionItem.fromJson(
              item as Map<String, dynamic>? ?? const {},
            ),
          )
          .toList(),
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
      total: _toInt(json['total']),
    );
  }
}

class WalletTransactionItem {
  final int id;
  final double amount;
  final int balanceType;
  final String direction;
  final String type;
  final String description;
  final String createdAt;
  final WalletReferenceUser? referenceUser;

  const WalletTransactionItem({
    required this.id,
    required this.amount,
    required this.balanceType,
    required this.direction,
    required this.type,
    required this.description,
    required this.createdAt,
    this.referenceUser,
  });

  factory WalletTransactionItem.fromJson(Map<String, dynamic> json) {
    return WalletTransactionItem(
      id: _toInt(json['id']),
      amount: _toDouble(json['amount']),
      balanceType: _toInt(json['balance_type']),
      direction: json['direction']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      referenceUser: json['reference_user'] == null
          ? null
          : WalletReferenceUser.fromJson(
              json['reference_user'] as Map<String, dynamic>,
            ),
    );
  }

  bool get isCredit => balanceType == 1;
}

class WalletReferenceUser {
  final int id;
  final String name;
  final String phoneNumber;

  const WalletReferenceUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory WalletReferenceUser.fromJson(Map<String, dynamic> json) {
    return WalletReferenceUser(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  final normalized = value?.toString().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1';
}
