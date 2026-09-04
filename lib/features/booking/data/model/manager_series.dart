/// One recurring booking as the venue sees it: the shape of the commitment,
/// and every session inside it.
class ManagerSeries {
  final int seriesId;
  final String status;
  final String customer;
  final String customerPhoneNo;
  final String branch;
  final String dayName;
  final String startTime;
  final String endTime;
  final String startsOn;
  final String endsOn;
  final int occurrenceCount;
  final double pricePerOccurrence;
  final double totalAmount;
  final bool payOnArrival;

  /// Whether the venue still has a decision to make. Only sessions that are
  /// actually pending count — a series where everything has been answered
  /// shows no buttons.
  final bool awaitingDecision;
  final int pendingCount;

  /// Weeks given up to somebody else's booking.
  final int skippedCount;
  final List<String> skippedDates;

  /// The money side of the series, counted over sessions that are still on.
  /// A cancelled week is not something the customer still owes for, so it is
  /// outside both sides of the sum.
  final double grossTotal;
  final double paidTotal;
  final double remainingTotal;
  final bool isFullyPaid;

  final List<SeriesOccurrence> occurrences;

  const ManagerSeries({
    required this.seriesId,
    required this.status,
    required this.customer,
    required this.customerPhoneNo,
    required this.branch,
    required this.dayName,
    required this.startTime,
    required this.endTime,
    required this.startsOn,
    required this.endsOn,
    required this.occurrenceCount,
    required this.pricePerOccurrence,
    required this.totalAmount,
    required this.payOnArrival,
    required this.awaitingDecision,
    required this.pendingCount,
    this.skippedCount = 0,
    this.skippedDates = const [],
    this.grossTotal = 0,
    this.paidTotal = 0,
    this.remainingTotal = 0,
    this.isFullyPaid = false,
    required this.occurrences,
  });

  factory ManagerSeries.fromJson(Map<String, dynamic> json) {
    return ManagerSeries(
      seriesId: _int(json['series_id']),
      status: _str(json['status']),
      customer: _str(json['customer']),
      customerPhoneNo: _str(json['customer_phone_no']),
      branch: _str(json['branch']),
      dayName: _str(json['day_name']),
      startTime: _str(json['start_time']),
      endTime: _str(json['end_time']),
      startsOn: _str(json['starts_on']),
      endsOn: _str(json['ends_on']),
      occurrenceCount: _int(json['occurrence_count']),
      pricePerOccurrence: _dbl(json['price_per_occurrence']),
      totalAmount: _dbl(json['total_amount']),
      payOnArrival: json['pay_on_arrival'] == true,
      awaitingDecision: json['awaiting_decision'] == true,
      pendingCount: _int(json['pending_count']),
      skippedCount: _int(json['skipped_count']),
      skippedDates: ((json['skipped_dates'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      grossTotal: _dbl(json['gross_total']),
      paidTotal: _dbl(json['paid_total']),
      remainingTotal: _dbl(json['remaining_total']),
      isFullyPaid: json['is_fully_paid'] == true,
      occurrences: ((json['occurrences'] as List?) ?? const [])
          .map((e) => SeriesOccurrence.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SeriesOccurrence {
  final int bookingId;
  final int sequence;
  final String date;
  final String startTime;
  final String endTime;
  final int status;
  final String statusName;
  final double serviceAmount;

  /// This session sits off the recurring pattern because the customer moved
  /// it. The date and time above are the real ones — this only explains why
  /// one week looks different.
  final bool isReplacement;
  final String replacementNote;

  /// What this one session has taken of the series payment, and what it still
  /// owes. A part-paid series is not "half paid everywhere" — it is the
  /// earliest weeks settled and the next one partly so.
  final double paidAmount;
  final int paymentStatus;
  final double remainingDue;

  const SeriesOccurrence({
    required this.bookingId,
    required this.sequence,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.statusName,
    required this.serviceAmount,
    this.isReplacement = false,
    this.replacementNote = '',
    this.paidAmount = 0,
    this.paymentStatus = 0,
    this.remainingDue = 0,
  });

  /// ServicePaymentStatus: 1 = Paid, 2 = Unpaid, 3 = PartialPaid.
  bool get isPaid => paymentStatus == 1;
  bool get isPartiallyPaid => paymentStatus == 3;
  bool get isUnpaid => !isPaid && !isPartiallyPaid;

  /// ServiceStatus: 1 = Processing, 2 = Approved, 3 = Cancel, 4 = Done.
  bool get isPending => status == 1;
  bool get isApproved => status == 2;
  bool get isCancelled => status == 3;
  bool get isDone => status == 4;

  /// The session's end time has already passed.
  ///
  /// A played session does not flip to [isDone] on its own — that only
  /// happens when a manager marks attendance — so a session can sit at
  /// [isApproved] long after it was actually played. Editing (or moving) a
  /// slot that already happened makes no sense regardless of what the status
  /// field still says, so this is checked on its own rather than folded into
  /// [isDone].
  bool get hasElapsed {
    final end = DateTime.tryParse('$date $endTime');
    return end != null && end.isBefore(DateTime.now());
  }

  factory SeriesOccurrence.fromJson(Map<String, dynamic> json) {
    return SeriesOccurrence(
      bookingId: _int(json['booking_id']),
      sequence: _int(json['sequence']),
      date: _str(json['date']),
      startTime: _str(json['start_time']),
      endTime: _str(json['end_time']),
      status: _int(json['status']),
      statusName: _str(json['statusName']),
      serviceAmount: _dbl(json['service_amount']),
      isReplacement: json['is_replacement'] == true,
      replacementNote: _str(json['replacement_note']),
      paidAmount: _dbl(json['paid_amount']),
      paymentStatus: _int(json['payment_status']),
      remainingDue: _dbl(json['remaining_due']),
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _dbl(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

String _str(dynamic v) {
  final s = v?.toString();
  return (s == null || s == 'null') ? '' : s;
}
