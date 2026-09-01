import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';

/// What the manager card is allowed to decide for itself: nothing.
///
/// A real 21:00–22:00 pay-on-arrival booking went unreported because this app
/// worked eligibility out locally, from `display_end_time` — a presentation
/// field the booking-list endpoint does not send for a normal booking — and
/// fell back to "ends at 23:59". The action appeared almost two hours late.
///
/// These tests pin the replacement: the server sends a decision, the card
/// renders it, and no cosmetic field can move it.
void main() {
  Map<String, dynamic> payload(Map<String, dynamic> extra) => {
        'id': 100016,
        'status': 2,
        'statusName': 'موافَق عليه',
        'payment_status': 2,
        'paymentStatusName': 'غير مدفوع',
        'payment_type': 1,
        'is_monthly': false,
        'customer': 'ayoubbelhaj',
        'branch': 'ملاعب الجدار',
        'service': 'سداسي 1',
        'date': '2026-08-28',
        'start_time': '2026-08-28 21:00:00',
        'end_time': '2026-08-28 22:00:00',
        'service_amount': 66,
        'paid_amount': 0,
        'due': 66,
        ...extra,
      };

  group('attendance eligibility comes from the server', () {
    test('5a. the flag is read straight from the payload', () {
      final eligible = BookingItemResponce.fromJson(
        payload({'can_report_attendance': true}),
      );
      final notYet = BookingItemResponce.fromJson(
        payload({'can_report_attendance': false}),
      );

      expect(eligible.canReportAttendance, isTrue);
      expect(notYet.canReportAttendance, isFalse);
    });

    test('5b. a missing display_end_time does not affect the decision', () {
      // The exact shape of the real bug: no presentation field at all. The
      // card must still know it may report, because the server said so.
      final booking = BookingItemResponce.fromJson(
        payload({'can_report_attendance': true}),
      );

      expect(booking.displayEndTime, '');
      expect(booking.canReportAttendance, isTrue);
    });

    test('5c. a present display_end_time cannot grant eligibility either', () {
      final booking = BookingItemResponce.fromJson(
        payload({'display_end_time': '22:00', 'can_report_attendance': false}),
      );

      // Cosmetics never open the action. Only the server's answer does.
      expect(booking.displayEndTime, '22:00');
      expect(booking.canReportAttendance, isFalse);
    });

    test('5d. an older server without the flag withholds the action', () {
      final booking = BookingItemResponce.fromJson(payload({}));

      // Withholding is a nuisance; showing it early invites a report the
      // backend will refuse. The safe default is the quiet one.
      expect(booking.canReportAttendance, isFalse);
    });

    test('5e. monthly membership does not change the answer', () {
      final normal = BookingItemResponce.fromJson(
        payload({'can_report_attendance': true}),
      );
      final monthly = BookingItemResponce.fromJson(
        payload({
          'can_report_attendance': true,
          'is_monthly': true,
          'series_id': 42,
          'series_sequence': 1,
          'display_end_time': '22:00',
        }),
      );

      expect(normal.canReportAttendance, monthly.canReportAttendance);
    });

    test('5f. attendance_status is carried through', () {
      final reported = BookingItemResponce.fromJson(
        payload({'attendance_status': 'no_show', 'can_report_attendance': false}),
      );

      expect(reported.attendanceStatus, 'no_show');
      expect(BookingItemResponce.fromJson(payload({})).attendanceStatus, 'unknown');
    });
  });

  group('a recorded result is final in the UI', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {
          'id': 100016, 'status': 2, 'statusName': 'موافَق عليه',
          'payment_status': 2, 'paymentStatusName': 'غير مدفوع',
          'payment_type': 1, 'is_monthly': false,
          'customer': 'ayoubbelhaj', 'branch': 'ملاعب الجدار', 'service': 'سداسي 1',
          'date': '2026-08-28', 'start_time': '2026-08-28 21:00:00',
          'end_time': '2026-08-28 22:00:00',
          'service_amount': 66, 'paid_amount': 0, 'due': 66,
          ...extra,
        };

    test('5g. an unreported booking offers the action', () {
      final b = BookingItemResponce.fromJson(
        base({'can_report_attendance': true, 'attendance_status': 'unknown'}),
      );

      expect(b.canReportAttendance, isTrue);
      expect(b.hasRecordedResult, isFalse);
    });

    test('5h. a reported booking shows a result and offers nothing', () {
      // The venue answered. It does not get a second answer — switching
      // «لم يحضر» to «تم اللعب» after the customer contests it would be the
      // venue marking its own homework.
      final b = BookingItemResponce.fromJson(base({
        'can_report_attendance': false,
        'attendance_status': 'no_show',
        'attendance_label': 'لم يحضر',
        'customer_confirmation': 'pending',
      }));

      expect(b.canReportAttendance, isFalse);
      expect(b.hasRecordedResult, isTrue);
      expect(b.attendanceLabel, 'لم يحضر');
      // Pending is information, not another decision.
      expect(b.customerConfirmation, 'pending');
    });

    test('5i. a contested no-show still leaves the manager locked out', () {
      final b = BookingItemResponce.fromJson(base({
        'can_report_attendance': false,
        'attendance_status': 'no_show',
        'attendance_label': 'لم يحضر',
        'customer_confirmation': 'attended',
      }));

      expect(b.canReportAttendance, isFalse);
      expect(b.hasRecordedResult, isTrue);
      expect(b.customerConfirmation, 'attended');
    });

    test('5j. venue fault records a result and carries no customer answer', () {
      final b = BookingItemResponce.fromJson(base({
        'can_report_attendance': false,
        'attendance_status': 'venue_issue',
        'attendance_label': 'مشكلة من الملعب',
        'customer_confirmation': null,
      }));

      expect(b.hasRecordedResult, isTrue);
      // Nothing was asked of the customer, so there is nothing to wait for.
      expect(b.customerConfirmation, isNull);
    });
  });
}
