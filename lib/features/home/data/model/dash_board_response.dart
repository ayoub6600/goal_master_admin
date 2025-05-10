class DashboardResponse {
  final bool status;
  final DashboardData data;

  DashboardResponse({
    required this.status,
    required this.data,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      status: json['status'].toString().toLowerCase() == 'true',
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
      status: _parseInt(json['status']),
      statusText: json['status_text'].toString(),
      serviceCount: _parseInt(json['serviceCount']),
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
      totalAllowedAmountToday: _parseInt(json['totalAllowedAmountToday']),
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
      paymentStatus: _parseInt(json['payment_status']),
      status: _parseInt(json['status']),
      paidAmount: json['paid_amount'].toString(),
      serviceAmount: json['service_amount'].toString(),
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
      type: _parseInt(json['type']),
      paymentBy: json['PaymentBy'].toString(),
      paidAmount: json['paid_amount'].toString(),
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
      schServiceId: _parseInt(json['sch_service_id']),
      title: json['title'].toString(),
      serviceCount: _parseInt(json['service_count']),
    );
  }
}

class TotalForgevin {
  final double dailyTotal;
  final double total;

  TotalForgevin({
    required this.dailyTotal,
    required this.total,
  });

  factory TotalForgevin.fromJson(Map<String, dynamic> json) {
    return TotalForgevin(
      dailyTotal: _parseDouble(json['dailyTotal']),
      total: _parseDouble(json['total']),
    );
  }
}

// 🔧 Helper functions
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
