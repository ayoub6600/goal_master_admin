class BookingDetails {
  final int id;
  final int cmnCustomerId;
  final String branch;
  final String address;
  final String latitude;
  final String longitude;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String service;
  final String serviceAmount;
  final String paidAmount;
  final int paymentStatus;
  final String paymentName;
  final String paymentType;
  final int status;
  final String statusName;
  final String? remarks;
  final String category;

  const BookingDetails({
    required this.id,
    required this.cmnCustomerId,
    required this.branch,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.service,
    required this.serviceAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.paymentName,
    required this.paymentType,
    required this.status,
    required this.statusName,
    this.remarks,
    required this.category,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      id: _asInt(json['id']),
      cmnCustomerId: _asInt(json['cmn_customer_id']),
      branch: _asString(json['branch']),
      address: _asString(json['address']),
      latitude: _asString(json['latitude']),
      longitude: _asString(json['longitude']),
      date: DateTime.parse(_asString(json['date'])),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      service: _asString(json['service']),
      serviceAmount: _asString(json['service_amount']),
      paidAmount: _asString(json['paid_amount']),
      paymentStatus: _asInt(json['payment_status']),
      paymentName: _asString(json['payment_name']),
      paymentType: _asString(json['payment_type']),
      status: _asInt(json['status']),
      statusName: _asString(json['status_name']),
      remarks: json['remarks']?.toString(),
      category: _asString(json['category']),
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
