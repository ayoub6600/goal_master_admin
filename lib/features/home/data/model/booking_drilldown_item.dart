class BookingDrilldownItem {
  final int id;
  final String date;
  final String startTime;
  final String branchName;
  final String customerName;
  final String customerPhone;
  final String serviceTitle;
  final double paidAmount;
  final double serviceAmount;
  final double dueAmount;

  /// The recurring booking this session belongs to, if any.
  final int? seriesId;
  final int seriesSequence;

  /// Already formatted by the server. Deriving the day from the raw datetime
  /// showed Saturday the 29th for a Sunday-the-30th booking, because Eloquent
  /// serialises a date cast to UTC.
  final String displayDate;
  final String displayStartTime;
  final String displayEndTime;

  bool get isMonthly => seriesId != null;

  BookingDrilldownItem({
    required this.id,
    required this.date,
    required this.startTime,
    required this.branchName,
    required this.customerName,
    required this.customerPhone,
    required this.serviceTitle,
    required this.paidAmount,
    required this.serviceAmount,
    required this.dueAmount,
    this.seriesId,
    this.seriesSequence = 0,
    this.displayDate = '',
    this.displayStartTime = '',
    this.displayEndTime = '',
  });

  factory BookingDrilldownItem.fromJson(Map<String, dynamic> json) {
    return BookingDrilldownItem(
      id: _asInt(json['id']),
      seriesId: json['booking_series_id'] == null
          ? null
          : _asInt(json['booking_series_id']),
      seriesSequence: _asInt(json['series_sequence']),
      displayDate: json['display_date']?.toString() ?? '',
      displayStartTime: json['display_start_time']?.toString() ?? '',
      displayEndTime: json['display_end_time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      branchName: json['branch']?['name']?.toString() ?? '',
      customerName: json['customer']?['full_name']?.toString() ?? '',
      customerPhone: json['customer']?['phone_no']?.toString() ?? '',
      serviceTitle: json['service']?['title']?.toString() ?? '',
      paidAmount: _asDouble(json['paid_amount']),
      serviceAmount: _asDouble(json['service_amount']),
      dueAmount: _asDouble(json['due_amount'] ??
          (json['service_amount'] != null && json['paid_amount'] != null
              ? (_asDouble(json['service_amount']) -
                  _asDouble(json['paid_amount']))
              : 0)),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
