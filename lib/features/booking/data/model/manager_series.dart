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
  });

  /// ServiceStatus: 1 = Processing, 2 = Approved, 3 = Cancel, 4 = Done.
  bool get isPending => status == 1;
  bool get isApproved => status == 2;
  bool get isCancelled => status == 3;
  bool get isDone => status == 4;

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
