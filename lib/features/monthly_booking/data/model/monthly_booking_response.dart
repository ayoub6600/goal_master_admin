class CustomerModel {
  final int id;
  final int userId;
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
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'] ?? '',
      phoneNo: json['phone_no'] ?? '',
      isPhoneVerified: json['is_phone_verified'] == 1,
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
  });

  factory MonthlyBookingResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyBookingResponse(
      id: json['id'],
      bookingDate: json['booking_date'],
      totalAmount: double.parse(json['total_amount']),
      paidAmount: double.parse(json['paid_amount']),
      dueAmount: double.parse(json['due_amount']),
      couponCode: json['coupon_code'],
      couponDiscount: double.parse(json['coupon_discount']),
      isDuePaid: json['is_due_paid'] == 1,
      remarks: json['remarks'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      customerId: json['cmn_customer_id'],
      payableAmount: double.parse(json['payable_amount']),
      isMonthly: json['is_monthly'] == 1,
      isMonthlyActive: json['is_monthly_active'] == 1,
      serviceBookingsAllCount: json['service_bookings_all_count'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      branchName: json['branch_name'],
      customer: CustomerModel.fromJson(json['customer']),
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
      status: json['status'],
      data: (json['data'] as List)
          .map((e) => MonthlyBookingResponse.fromJson(e))
          .toList(),
    );
  }
}
