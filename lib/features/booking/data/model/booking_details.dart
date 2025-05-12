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
      id: json['id'],
      cmnCustomerId: json['cmn_customer_id'],
      branch: json['branch'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      service: json['service'],
      serviceAmount: json['service_amount'],
      paidAmount: json['paid_amount'],
      paymentStatus: json['payment_status'],
      paymentName: json['payment_name'],
      paymentType: json['payment_type'],
      status: json['status'],
      statusName: json['status_name'],
      remarks: json['remarks'],
      category: json['category'],
    );
  }
}
