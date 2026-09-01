// The monthly-booking list, as the server sends it.
//
// Every field here is read through a tolerant helper on purpose. The amount
// columns are SQL decimals, and a decimal does not have one JSON shape: some
// drivers hand them over as strings ("66.00"), others as numbers (66). The
// original code called `double.parse` on them directly, so the screen worked
// against one database and died with
// `type 'int' is not a subtype of type 'String'` against another — a crash
// with no relation to the manager's data being right or wrong.
//
// The same reasoning covers the text fields: `branch_name` comes from a LEFT
// JOIN and is legitimately null when a booking's branch row is gone, which
// must render as an empty label rather than take the screen down.
class CustomerModel {
  final int id;
  final int? userId;
  final String fullName;
  final String phoneNo;
  final bool isPhoneVerified;

  CustomerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNo,
    required this.isPhoneVerified,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: _int(json['id']),
      userId: _intOrNull(json['user_id']),
      fullName: _str(json['full_name']),
      phoneNo: _str(json['phone_no']),
      isPhoneVerified: _bool(json['is_phone_verified']),
    );
  }
}

class MonthlyBookingResponse {
  final int id;
  final String bookingDate;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String? couponCode;
  final double couponDiscount;
  final bool isDuePaid;
  final String? remarks;
  final int createdBy;
  final int? updatedBy;
  final String createdAt;
  final String updatedAt;
  final int customerId;
  final double payableAmount;
  final bool isMonthly;
  final bool isMonthlyActive;
  final int serviceBookingsAllCount;
  final String date;
  final String startTime;
  final String endTime;
  final String branchName;
  final CustomerModel customer;

  // ---- Recurring-booking context -------------------------------------
  // Present only on the monthly list, which asks for it explicitly. Each of
  // these rows is ONE session; `seriesId` is what says which sessions belong
  // to the same monthly booking. Zero means a legacy row with no series.

  /// The `sch_service_bookings` row behind this session — the id every
  /// per-occurrence action (payment, status, cancel) is keyed by.
  final int bookingId;

  final int seriesId;

  /// 1-based position inside the series.
  final int sequence;

  /// Server-recorded: this session was moved off the recurring pattern.
  /// Never inferred from the clock.
  final bool isReplacement;

  /// ServiceStatus of the session itself: 1 Processing, 2 Approved,
  /// 3 Cancel, 4 Done.
  final int bookingStatus;

  /// ServicePaymentStatus: 1 Paid, 2 Unpaid, 3 PartialPaid.
  final int bookingPaymentStatus;

  final double serviceAmount;
  final double occurrencePaidAmount;

  /// The session's own date, from the session row rather than the envelope.
  final String occurrenceDate;

  /// The authoritative start and end of this session: real date AND real
  /// clock, in one value.
  ///
  /// `start_time` is a legacy DATETIME whose date half is the series creation
  /// day, and `date` carries the day without the time. `start_at`/`end_at` are
  /// the occurrence model's own columns and carry both correctly — they are
  /// what the booking engine itself works from. Empty on rows written before
  /// that model existed, which is why the readers below fall back.
  final String startAt;
  final String endAt;

  /// What a reschedule needs to send back unchanged. Moving a session replays
  /// the booking's own values for everything except the slot, so nothing else
  /// can drift as a side effect of changing the time.
  final int branchId;
  final int serviceId;
  final int employeeId;
  final int paymentTypeId;
  final String bookingRemarks;

  /// The result the venue reported for THIS session, and whether it may be
  /// reported now — both decided by the server's attendance authority.
  ///
  /// Per session, never per series: four weeks can legitimately end four
  /// different ways, and one of them being playable today says nothing about
  /// the three that have not happened yet.
  final String attendanceStatus;
  final String attendanceLabel;
  final bool canReportAttendance;
  final bool payOnArrival;

  bool get hasReportedResult =>
      attendanceStatus.isNotEmpty && attendanceStatus != 'unknown';

  bool get belongsToSeries => seriesId > 0;
  bool get isCancelled => bookingStatus == 3;
  bool get isDone => bookingStatus == 4;

  MonthlyBookingResponse({
    required this.id,
    required this.bookingDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    this.couponCode,
    required this.couponDiscount,
    required this.isDuePaid,
    this.remarks,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    required this.payableAmount,
    required this.isMonthly,
    required this.isMonthlyActive,
    required this.serviceBookingsAllCount,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.branchName,
    required this.customer,
    this.bookingId = 0,
    this.seriesId = 0,
    this.sequence = 0,
    this.isReplacement = false,
    this.bookingStatus = 0,
    this.bookingPaymentStatus = 0,
    this.serviceAmount = 0,
    this.occurrencePaidAmount = 0,
    this.occurrenceDate = '',
    this.startAt = '',
    this.endAt = '',
    this.branchId = 0,
    this.serviceId = 0,
    this.employeeId = 0,
    this.paymentTypeId = 0,
    this.bookingRemarks = '',
    this.attendanceStatus = 'unknown',
    this.attendanceLabel = '',
    this.canReportAttendance = false,
    this.payOnArrival = false,
  });

  factory MonthlyBookingResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyBookingResponse(
      id: _int(json['id']),
      bookingDate: _str(json['booking_date']),
      totalAmount: _double(json['total_amount']),
      paidAmount: _double(json['paid_amount']),
      dueAmount: _double(json['due_amount']),
      couponCode: _strOrNull(json['coupon_code']),
      couponDiscount: _double(json['coupon_discount']),
      isDuePaid: _bool(json['is_due_paid']),
      remarks: _strOrNull(json['remarks']),
      createdBy: _int(json['created_by']),
      updatedBy: _intOrNull(json['updated_by']),
      createdAt: _str(json['created_at']),
      updatedAt: _str(json['updated_at']),
      customerId: _int(json['cmn_customer_id']),
      payableAmount: _double(json['payable_amount']),
      isMonthly: _bool(json['is_monthly']),
      isMonthlyActive: _bool(json['is_monthly_active']),
      serviceBookingsAllCount: _int(json['service_bookings_all_count']),
      date: _str(json['date']),
      startTime: _str(json['start_time']),
      endTime: _str(json['end_time']),
      branchName: _str(json['branch_name']),
      bookingId: _int(json['booking_id']),
      seriesId: _int(json['booking_series_id']),
      sequence: _int(json['series_sequence']),
      isReplacement: _bool(json['is_replacement']),
      bookingStatus: _int(json['booking_status']),
      bookingPaymentStatus: _int(json['booking_payment_status']),
      serviceAmount: _double(json['booking_service_amount']),
      occurrencePaidAmount: _double(json['booking_paid_amount']),
      occurrenceDate: _str(json['occurrence_date']),
      startAt: _str(json['start_at']),
      endAt: _str(json['end_at']),
      branchId: _int(json['cmn_branch_id']),
      serviceId: _int(json['sch_service_id']),
      employeeId: _int(json['sch_employee_id']),
      paymentTypeId: _int(json['cmn_payment_type_id']),
      bookingRemarks: _str(json['booking_remarks']),
      attendanceStatus: json['attendance_status'] == null
          ? 'unknown'
          : _str(json['attendance_status']),
      attendanceLabel: _str(json['attendance_label']),
      // Defaults to false for an older server: withholding the action is a
      // nuisance, offering it too early invites a report the backend refuses.
      canReportAttendance: _bool(json['can_report_attendance']),
      payOnArrival: _bool(json['pay_on_arrival']),
      customer: CustomerModel.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}

class MonthlyBookingListResponse {
  final String status;
  final List<MonthlyBookingResponse> data;

  MonthlyBookingListResponse({
    required this.status,
    required this.data,
  });

  factory MonthlyBookingListResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyBookingListResponse(
      status: _str(json['status']),
      data: ((json['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => MonthlyBookingResponse.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Tolerant readers.
//
// These accept whatever JSON shape the field arrives in and never throw. A
// list screen refusing to render because an amount came back as `66` instead
// of `"66.00"` is a worse failure than showing the amount.
// ---------------------------------------------------------------------------

int _int(dynamic v) => _intOrNull(v) ?? 0;

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is bool) return v ? 1 : 0;
  final parsed = num.tryParse(v.toString());
  return parsed?.toInt();
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v == null) return 0;
  return double.tryParse(v.toString()) ?? 0;
}

String _str(dynamic v) => _strOrNull(v) ?? '';

String? _strOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/// Truthiness as this API expresses it: 1 / "1" / true.
bool _bool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  return s == '1' || s == 'true';
}
