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
      due: _asString(json['due']),
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
