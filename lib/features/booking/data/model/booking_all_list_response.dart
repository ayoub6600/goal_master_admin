class BookingItemResponce {
  final int id;
  final int status;
  final String statusName;
  final int paymentStatus;
  final String paymentStatusName;
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
      id: json['id'],
      status: json['status'],
      statusName: json['statusName'],
      paymentStatus: json['payment_status'],
      paymentStatusName: json['paymentStatusName'],
      customer: json['customer'],
      customerPhoneNo: json['customer_phone_no'],
      employee: json['employee'],
      branch: json['branch'],
      service: json['service'],
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      remarks: json['remarks'],
      serviceAmount: json['service_amount'],
      paidAmount: json['paid_amount'],
      due: json['due'],
    );
  }
}
