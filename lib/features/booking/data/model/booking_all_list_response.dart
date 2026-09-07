class BookingItemResponce {
  final int id;
  final int status;
  final String statusName;
  final int paymentStatus;
  final String paymentStatusName;
  final int paymentType;
  final String customer;
  final String customerPhoneNo;
  final String employee;
  final String branch;
  final String service;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? remarks;
  final String serviceAmount;
  final String paidAmount;
  final String due;

  /// Present only when this row stands for a whole recurring booking. The
  /// list shows a series as ONE row — four identical cards asking the same
  /// question is noise, and it invites accepting some sessions and refusing
  /// others, which is not what the customer bought.
  final int? seriesId;
  final int seriesOccurrenceCount;
  final String? seriesLabel;
  final String? seriesStartsOn;
  final String? seriesEndsOn;
  final double seriesTotalAmount;
  final bool payOnArrival;

  /// Weeks the customer gave up because somebody else already had them. The
  /// venue should know the four sessions are not four consecutive weeks
  /// before agreeing to them.
  final int seriesSkippedCount;
  final List<String> seriesSkippedDates;

  /// Calendar values already formatted by the server.
  ///
  /// PRESENTATION ONLY. These must never decide a business rule: they are
  /// optional, they were historically sent for monthly bookings alone, and
  /// something that can legitimately be absent cannot be allowed to gate money.
  /// See [canReportAttendance] for the eligibility answer.
  final String displayDate;
  final String displayStartTime;
  final String displayEndTime;

  /// Whether the venue may report attendance, as decided by the SERVER.
  ///
  /// Rendered, never recomputed. The app used to work this out from
  /// [displayEndTime] — a field the booking-list endpoint did not send — and
  /// fell back to "ends at 23:59", hiding the attendance action for two hours
  /// after the slot had finished. Eligibility is a rule about money, so it is
  /// answered once, by the service that also guards the submission.
  ///
  /// Defaults to false for an older server: withholding the button is a
  /// nuisance, showing it too early invites a report the backend will refuse.
  final bool canReportAttendance;

  /// unknown | attended | no_show | venue_issue | customer_issue
  final String attendanceStatus;

  /// The recorded result in the venue's own words, from the server.
  final String attendanceLabel;

  /// Where the customer's side of a no-show stands: pending | attended |
  /// did_not_attend, or null when this is not a no-show.
  ///
  /// Informational only. The manager's own report is final regardless of what
  /// the customer answers — this exists so the card can say "waiting" instead
  /// of looking unfinished.
  final String? customerConfirmation;

  /// The manager's structured venue-fault reason, already worded by the
  /// server. Empty for every other outcome.
  final String venueFaultReasonLabel;

  /// What actually happened to the money on a cancelled booking — null for
  /// one still active, or one paid on arrival.
  final BookingCancellation? cancellation;

  /// Whether a result has already been recorded. First report wins.
  bool get hasRecordedResult =>
      attendanceStatus.isNotEmpty && attendanceStatus != 'unknown';

  bool get isMonthly => seriesId != null;

  const BookingItemResponce({
    required this.id,
    required this.status,
    required this.statusName,
    required this.paymentStatus,
    required this.paymentStatusName,
    required this.paymentType,
    required this.customer,
    required this.customerPhoneNo,
    required this.employee,
    required this.branch,
    required this.service,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.remarks,
    required this.serviceAmount,
    required this.paidAmount,
    required this.due,
    this.seriesId,
    this.seriesOccurrenceCount = 0,
    this.seriesLabel,
    this.seriesStartsOn,
    this.seriesEndsOn,
    this.seriesTotalAmount = 0,
    this.payOnArrival = false,
    this.seriesSkippedCount = 0,
    this.seriesSkippedDates = const [],
    this.displayDate = '',
    this.displayStartTime = '',
    this.displayEndTime = '',
    this.canReportAttendance = false,
    this.attendanceStatus = 'unknown',
    this.attendanceLabel = '',
    this.customerConfirmation,
    this.venueFaultReasonLabel = '',
    this.cancellation,
  });

  static BookingItemResponce fromJson(Map<String, dynamic> json) {
    return BookingItemResponce(
      id: _asInt(json['id']),
      status: _asInt(json['status']),
      statusName: _asString(json['statusName']),
      paymentStatus: _asInt(json['payment_status']),
      paymentStatusName: _asString(json['paymentStatusName']),
      paymentType: _asInt(json['payment_type']),
      customer: _asString(json['customer']),
      customerPhoneNo: _asString(json['customer_phone_no']),
      employee: _asString(json['employee']),
      branch: _asString(json['branch']),
      service: _asString(json['service']),
      date: DateTime.parse(_asString(json['date'])),
      startTime: DateTime.parse(_asString(json['start_time'])),
      endTime: DateTime.parse(_asString(json['end_time'])),
      remarks: json['remarks']?.toString(),
      serviceAmount: _asString(json['service_amount']),
      paidAmount: _asString(json['paid_amount']),
      seriesId: json['series_id'] == null ? null : _asInt(json['series_id']),
      seriesOccurrenceCount: _asInt(json['series_occurrence_count']),
      seriesLabel: json['series_label']?.toString(),
      seriesStartsOn: json['series_starts_on']?.toString(),
      seriesEndsOn: json['series_ends_on']?.toString(),
      seriesTotalAmount:
          double.tryParse(json['series_total_amount']?.toString() ?? '') ?? 0,
      payOnArrival: json['pay_on_arrival'] == true,
      seriesSkippedCount: _asInt(json['series_skipped_count']),
      seriesSkippedDates: ((json['series_skipped_dates'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      displayDate: _asString(json['display_date']),
      displayStartTime: _asString(json['display_start_time']),
      displayEndTime: _asString(json['display_end_time']),
      canReportAttendance: json['can_report_attendance'] == true ||
          json['can_report_attendance'] == 1,
      attendanceStatus: _asString(json['attendance_status']).isEmpty
          ? 'unknown'
          : _asString(json['attendance_status']),
      attendanceLabel: _asString(json['attendance_label']),
      customerConfirmation: json['customer_confirmation'] == null
          ? null
          : _asString(json['customer_confirmation']),
      venueFaultReasonLabel: _asString(json['venue_fault_reason_label']),
      due: _asString(json['due']),
      cancellation: json['cancellation'] is Map<String, dynamic>
          ? BookingCancellation.fromJson(
              json['cancellation'] as Map<String, dynamic>)
          : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }
}

/// What actually happened to the money on a cancelled booking — how much
/// came back to the customer, and how much the venue kept as a fee.
class BookingCancellation {
  final double paidAmount;
  final double refundAmount;
  final double retainedAmount;

  const BookingCancellation({
    required this.paidAmount,
    required this.refundAmount,
    required this.retainedAmount,
  });

  /// A real fee was retained — the case worth calling out visually.
  bool get hasPenalty => retainedAmount > 0.001;

  static BookingCancellation fromJson(Map<String, dynamic> json) {
    return BookingCancellation(
      paidAmount: _asDouble(json['paid_amount']),
      refundAmount: _asDouble(json['refund_amount']),
      retainedAmount: _asDouble(json['retained_amount']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
