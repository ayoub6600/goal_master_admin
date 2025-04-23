class DashboardResponse {
  final bool status;
  final DashboardData data;

  DashboardResponse({
    required this.status,
    required this.data,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      status: json['status'] == "true",
      data: DashboardData.fromJson(json['data']),
    );
  }
}

class DashboardData {
  final BookingStatus bookingStatus;
  final IncomAndOtherStatistics incomAndOtherStatistics;
  final List<TopService> topService;
  final TotalForgevin totalForgevin;

  DashboardData({
    required this.bookingStatus,
    required this.incomAndOtherStatistics,
    required this.topService,
    required this.totalForgevin,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      bookingStatus: BookingStatus.fromJson(json['bookingStatus']),
      incomAndOtherStatistics:
          IncomAndOtherStatistics.fromJson(json['incomAndOtherStatistics']),
      topService: (json['topService'] as List)
          .map((e) => TopService.fromJson(e))
          .toList(),
      totalForgevin: TotalForgevin.fromJson(json['totalForgevin']),
    );
  }
}

class BookingStatus {
  final List<BookingInfo> totalBooking;
  final List<BookingInfo> todayBooking;

  BookingStatus({
    required this.totalBooking,
    required this.todayBooking,
  });

  factory BookingStatus.fromJson(Map<String, dynamic> json) {
    return BookingStatus(
      totalBooking: (json['totalBooking'] as List)
          .map((e) => BookingInfo.fromJson(e))
          .toList(),
      todayBooking: (json['todayBooking'] as List)
          .map((e) => BookingInfo.fromJson(e))
          .toList(),
    );
  }
}

class BookingInfo {
  final int status;
  final String statusText;
  final int serviceCount;

  BookingInfo({
    required this.status,
    required this.statusText,
    required this.serviceCount,
  });

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      status: json['status'],
      statusText: json['status_text'],
      serviceCount: json['serviceCount'],
    );
  }
}

class IncomAndOtherStatistics {
  final List<TodayPaidAndDue> todayPaidAndDue;
  final List<TodayPaidBy> todayPaidBy;
  final int totalAllowedAmountToday;

  IncomAndOtherStatistics({
    required this.todayPaidAndDue,
    required this.todayPaidBy,
    required this.totalAllowedAmountToday,
  });

  factory IncomAndOtherStatistics.fromJson(Map<String, dynamic> json) {
    return IncomAndOtherStatistics(
      todayPaidAndDue: (json['todayPaidAndDue'] as List)
          .map((e) => TodayPaidAndDue.fromJson(e))
          .toList(),
      todayPaidBy: (json['todayPaidBy'] as List)
          .map((e) => TodayPaidBy.fromJson(e))
          .toList(),
      totalAllowedAmountToday: json['totalAllowedAmountToday'],
    );
  }
}

class TodayPaidAndDue {
  final int paymentStatus;
  final int status;
  final String paidAmount;
  final String serviceAmount;

  TodayPaidAndDue({
    required this.paymentStatus,
    required this.status,
    required this.paidAmount,
    required this.serviceAmount,
  });

  factory TodayPaidAndDue.fromJson(Map<String, dynamic> json) {
    return TodayPaidAndDue(
      paymentStatus: json['payment_status'],
      status: json['status'],
      paidAmount: json['paid_amount'],
      serviceAmount: json['service_amount'],
    );
  }
}

class TodayPaidBy {
  final int type;
  final String paymentBy;
  final String paidAmount;

  TodayPaidBy({
    required this.type,
    required this.paymentBy,
    required this.paidAmount,
  });

  factory TodayPaidBy.fromJson(Map<String, dynamic> json) {
    return TodayPaidBy(
      type: json['type'],
      paymentBy: json['PaymentBy'],
      paidAmount: json['paid_amount'],
    );
  }
}

class TopService {
  final int schServiceId;
  final String title;
  final int serviceCount;

  TopService({
    required this.schServiceId,
    required this.title,
    required this.serviceCount,
  });

  factory TopService.fromJson(Map<String, dynamic> json) {
    return TopService(
      schServiceId: json['sch_service_id'],
      title: json['title'],
      serviceCount: json['service_count'],
    );
  }
}

class TotalForgevin {
  final int dailyTotal;
  final int total;

  TotalForgevin({
    required this.dailyTotal,
    required this.total,
  });

  factory TotalForgevin.fromJson(Map<String, dynamic> json) {
    return TotalForgevin(
      dailyTotal: json['dailyTotal'],
      total: json['total'],
    );
  }
}
