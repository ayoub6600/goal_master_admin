/// The recurring booking the server actually created.
///
/// The success screen used to be built from the single occurrence the manager
/// had selected, so a four-week booking reported the price of its first
/// appointment — «66 د.ل» for a 264 د.ل commitment. Nothing on that screen was
/// the server's answer; it was the request, echoed back.
///
/// This is the server's answer: its own occurrence list, its own total. The
/// app adds nothing up.
class CreatedSeries {
  const CreatedSeries({
    required this.seriesId,
    required this.occurrenceCount,
    required this.totalAmount,
    required this.pricePerOccurrence,
    required this.occurrences,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.paymentStatus = 2,
    this.branch = '',
    this.dayName = '',
  });

  final int seriesId;
  final int occurrenceCount;

  /// The authoritative total. Never first price × count.
  final double totalAmount;
  final double pricePerOccurrence;

  /// What the venue reports collecting, and what is still owed. Server
  /// figures — the app sums nothing.
  final double paidAmount;
  final double remainingAmount;

  /// ServicePaymentStatus: 1 Paid, 2 Unpaid, 3 PartialPaid.
  final int paymentStatus;

  String get paymentLabel => switch (paymentStatus) {
        1 => 'خالص',
        3 => 'مدفوع جزئي',
        _ => 'غير مدفوع',
      };
  final List<CreatedOccurrence> occurrences;
  final String branch;
  final String dayName;

  /// True when the venue prices every appointment the same, which is the only
  /// case where a "× 66" breakdown is honest.
  bool get hasUniformPrice =>
      occurrences.map((o) => o.price).toSet().length <= 1;

  static CreatedSeries? tryFrom(Map<String, dynamic>? data) {
    if (data == null || data['series_id'] == null) return null;

    return CreatedSeries(
      seriesId: _int(data['series_id']),
      occurrenceCount: _int(data['occurrence_count']),
      totalAmount: _double(data['total_amount']),
      pricePerOccurrence: _double(data['price_per_occurrence']),
      paidAmount: _double(data['paid_amount']),
      remainingAmount: _double(data['remaining_amount']),
      paymentStatus: data['payment_status'] == null
          ? 2
          : _int(data['payment_status']),
      branch: (data['branch'] ?? '').toString(),
      dayName: (data['day_name'] ?? '').toString(),
      occurrences: ((data['occurrences'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => CreatedOccurrence.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// One appointment of the created series, as stored.
class CreatedOccurrence {
  const CreatedOccurrence({
    required this.sequence,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.startAt,
    this.endAt,
    this.price = 0,
    this.isReplacement = false,
    this.originalDate = '',
    this.originalStartTime = '',
  });

  final int sequence;
  final String date;
  final String startTime;
  final String endTime;
  final DateTime? startAt;
  final DateTime? endAt;
  final double price;

  /// This appointment stands in for one the recurrence could not have.
  final bool isReplacement;
  final String originalDate;
  final String originalStartTime;

  factory CreatedOccurrence.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    // `start_at` when the server sends it; otherwise the date and clock it
    // stored, combined here only because both halves came from the same row.
    final startAt = parse(json['start_at']) ??
        parse('${json['date']} ${json['start_time']}');
    final endAt = parse(json['end_at']) ??
        parse('${json['date']} ${json['end_time']}');

    return CreatedOccurrence(
      sequence: _int(json['sequence']),
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      startAt: startAt,
      endAt: endAt,
      price: _double(json['price'] ?? json['service_amount']),
      isReplacement: json['is_replacement'] == true,
      originalDate: (json['original_date'] ?? '').toString(),
      originalStartTime: (json['original_start_time'] ?? '').toString(),
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
