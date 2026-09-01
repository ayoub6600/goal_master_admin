import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';

/// One session of a monthly booking, in the shape the server sends.
///
/// Built through `fromJson` rather than the constructor so the tests exercise
/// the same parsing the app runs against a live response.
MonthlyBookingResponse occurrence({
  required int id,
  required int seriesId,
  required int seq,
  required String date,
  double amount = 66,
  double paid = 0,
  int status = 2,
  bool replacement = false,
  String startTime = '2026-08-30 20:00:00',
  String endTime = '2026-08-30 21:00:00',
  String customer = 'ayoubbelhaj',
  String branch = 'ملاعب الجدار',
  bool monthlyActive = true,
  String attendance = 'unknown',
  bool canReport = false,
}) {
  return MonthlyBookingResponse.fromJson({
    'id': id,
    'booking_date': date,
    'total_amount': amount,
    'paid_amount': paid,
    'due_amount': amount - paid,
    'coupon_code': null,
    'coupon_discount': 0,
    'is_due_paid': 0,
    'remarks': null,
    'created_by': 38,
    'updated_by': null,
    'created_at': '2026-08-30T11:46:27.000000Z',
    'updated_at': '2026-08-30T11:46:27.000000Z',
    'cmn_customer_id': 58,
    'payable_amount': amount,
    'is_monthly': 1,
    'is_monthly_active': monthlyActive ? 1 : 0,
    'service_bookings_all_count': 1,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'branch_name': branch,
    // Deliberately far from the series ids used in tests: a fixture whose
    // booking id can collide with a series id turns "it sent the session, not
    // the series" into an assertion that passes by coincidence.
    'booking_id': 900000 + id,
    'booking_series_id': seriesId,
    'series_sequence': seq,
    'is_replacement': replacement ? 1 : 0,
    'booking_status': status,
    'booking_payment_status': paid <= 0 ? 2 : (paid >= amount ? 1 : 3),
    'booking_service_amount': amount,
    'booking_paid_amount': paid,
    'occurrence_date': date,
    'attendance_status': attendance,
    'attendance_label': switch (attendance) {
      'attended' => 'تم اللعب',
      'no_show' => 'لم يحضر',
      'venue_issue' => 'مشكلة من الملعب',
      _ => 'لم يُحدد',
    },
    'can_report_attendance': canReport ? 1 : 0,
    'pay_on_arrival': 1,
    // The engine's own columns: real date and real clock together.
    'start_at': '$date ${_timeOf(startTime)}',
    'end_at': '$date ${_timeOf(endTime)}',
    'customer': {
      'id': 58,
      'user_id': 45,
      'full_name': customer,
      'phone_no': '0916776600',
      'is_phone_verified': 1,
    },
  });
}

/// Captured from `GET user/booking/getMonthlyBookingList` against the real
/// database: four sessions of series 100002, one of them a replacement moved
/// to a later hour.
final realMonthlyPayload = <String, dynamic>{
  'status': '1',
  'data': [
    _row(286, 100027, 4, '2026-09-20', '20:00:00', 0),
    _row(285, 100026, 3, '2026-09-13', '20:00:00', 0),
    _row(284, 100025, 2, '2026-09-06', '22:00:00', 1),
    _row(283, 100024, 1, '2026-08-30', '20:00:00', 0),
  ],
};

Map<String, dynamic> _row(
  int id,
  int bookingId,
  int seq,
  String date,
  String clock,
  int replacement,
) {
  final endHour = int.parse(clock.substring(0, 2)) + 1;

  return {
    'id': id,
    'booking_date': date,
    // Sent as bare numbers by this driver — the shape that used to crash the
    // screen when it was parsed with double.parse.
    'total_amount': 66,
    'paid_amount': 0,
    'due_amount': 66,
    'coupon_code': null,
    'coupon_discount': 0,
    'is_due_paid': 0,
    'remarks': null,
    'created_by': 38,
    'updated_by': null,
    'created_at': '2026-08-30T11:46:27.000000Z',
    'updated_at': '2026-08-30T11:46:27.000000Z',
    'cmn_customer_id': 58,
    'payable_amount': 66,
    'is_monthly': 1,
    'is_monthly_active': 1,
    'service_bookings_all_count': 1,
    'date': date,
    // The date half is the series creation day for every row — a schema
    // artefact the screen must not read a session's day from.
    'start_time': '2026-08-30 $clock',
    'end_time': '2026-08-30 ${endHour.toString().padLeft(2, '0')}:00:00',
    'branch_name': 'ملاعب الجدار',
    'booking_id': bookingId,
    'booking_series_id': 100002,
    'series_sequence': seq,
    'is_replacement': replacement,
    'booking_status': 2,
    'booking_payment_status': 2,
    'booking_service_amount': 66,
    'booking_paid_amount': 0,
    'occurrence_date': date,
    'start_at': '$date $clock',
    'end_at': '$date ${endHour.toString().padLeft(2, '0')}:00:00',
    'customer': {
      'id': 58,
      'user_id': 45,
      'full_name': 'ayoubbelhaj',
      'phone_no': '0916776600',
      'is_phone_verified': 1,
    },
  };
}

/// The clock half of «2026-08-30 20:00:00» or of «20:00:00».
String _timeOf(String raw) {
  final parts = raw.trim().split(' ');
  return parts.length > 1 ? parts.last : raw.trim();
}

/// A row from a server that predates the attendance fields on this endpoint.
class MonthlyBookingResponseFixture {
  static MonthlyBookingResponse withoutAttendanceFields() {
    final json = Map<String, dynamic>.from(
      (realMonthlyPayload['data'] as List).first as Map,
    )
      ..remove('attendance_status')
      ..remove('attendance_label')
      ..remove('can_report_attendance')
      ..remove('pay_on_arrival');

    return MonthlyBookingResponse.fromJson(json);
  }
}
