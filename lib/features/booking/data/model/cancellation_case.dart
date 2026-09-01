/// A customer's appeal, as the venue sees it.
///
/// Carries the money three ways — what the session was worth, what the
/// customer already got back, and what the venue is holding — because
/// approving means giving back some of the third, and a manager cannot judge
/// that without seeing all of it.
class CancellationExceptionCase {
  final int id;
  final int bookingId;
  final String status;
  final String reasonLabel;
  final String? reasonText;
  final double allocationAmount;
  final double policyRefundAmount;
  final double retainedAmount;
  final double grantedAmount;
  final bool isMonthly;
  final String customer;
  final String date;
  final String time;

  const CancellationExceptionCase({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.reasonLabel,
    this.reasonText,
    this.allocationAmount = 0,
    this.policyRefundAmount = 0,
    this.retainedAmount = 0,
    this.grantedAmount = 0,
    this.isMonthly = false,
    this.customer = '',
    this.date = '',
    this.time = '',
  });

  factory CancellationExceptionCase.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

    return CancellationExceptionCase(
      id: json['id'] is int ? json['id'] as int : 0,
      bookingId: json['booking_id'] is int ? json['booking_id'] as int : 0,
      status: json['status']?.toString() ?? '',
      reasonLabel: json['reason_label']?.toString() ?? '',
      reasonText: json['reason_text']?.toString(),
      allocationAmount: d(json['allocation_amount']),
      policyRefundAmount: d(json['policy_refund_amount']),
      retainedAmount: d(json['retained_amount']),
      grantedAmount: d(json['granted_amount']),
      isMonthly: json['is_monthly'] == true,
      customer: json['customer']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }
}

/// A finished session nobody has reported on yet.
class AwaitingAttendanceBooking {
  final int bookingId;
  final String customer;
  final String date;
  final String time;
  final bool isMonthly;
  final bool payOnArrival;

  const AwaitingAttendanceBooking({
    required this.bookingId,
    this.customer = '',
    this.date = '',
    this.time = '',
    this.isMonthly = false,
    this.payOnArrival = false,
  });

  factory AwaitingAttendanceBooking.fromJson(Map<String, dynamic> json) {
    return AwaitingAttendanceBooking(
      bookingId: json['booking_id'] is int ? json['booking_id'] as int : 0,
      customer: json['customer']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isMonthly: json['is_monthly'] == true,
      payOnArrival: json['pay_on_arrival'] == true,
    );
  }
}
