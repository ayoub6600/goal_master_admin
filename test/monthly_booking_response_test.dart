import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';

/// The «الحجز الشهري» screen died with
/// `type 'int' is not a subtype of type 'String'` because the amount fields
/// were read with `double.parse`, which only accepts a String. The server had
/// always been free to send `66` rather than `"66.00"` — SQL decimals have no
/// single JSON shape — so the screen was one database driver away from being
/// unopenable, with nothing wrong with the manager's bookings at all.
///
/// These tests pin the shapes, not the parser: whichever way an amount, a
/// flag, or a nullable joined column arrives, the list still renders.
void main() {
  Map<String, dynamic> row(Map<String, dynamic> overrides) => {
        'id': 286,
        'booking_date': '2026-09-20',
        'total_amount': '66.00',
        'paid_amount': '0.00',
        'due_amount': '66.00',
        'coupon_code': null,
        'coupon_discount': '0.00',
        'is_due_paid': 0,
        'remarks': null,
        'created_by': 38,
        'updated_by': null,
        'created_at': '2026-08-30T11:46:27.000000Z',
        'updated_at': '2026-08-30T11:46:27.000000Z',
        'cmn_customer_id': 58,
        'payable_amount': '66.00',
        'is_monthly': 1,
        'is_monthly_active': 1,
        'service_bookings_all_count': 4,
        'date': '2026-09-20',
        'start_time': '2026-08-30 20:00:00',
        'end_time': '2026-08-30 21:00:00',
        'branch_name': 'ملاعب الجدار',
        'customer': {
          'id': 58,
          'user_id': 45,
          'full_name': 'ayoubbelhaj',
          'phone_no': '0916776600',
          'is_phone_verified': 1,
        },
        ...overrides,
      };

  group('amounts survive every JSON shape a decimal can take', () {
    test('string decimals, as the older driver sent them', () {
      final b = MonthlyBookingResponse.fromJson(row({}));

      expect(b.totalAmount, 66);
      expect(b.dueAmount, 66);
      expect(b.paidAmount, 0);
      expect(b.payableAmount, 66);
    });

    test('bare integers — the exact payload that crashed the screen', () {
      final b = MonthlyBookingResponse.fromJson(row({
        'total_amount': 66,
        'paid_amount': 0,
        'due_amount': 66,
        'coupon_discount': 0,
        'payable_amount': 66,
      }));

      expect(b.totalAmount, 66);
      expect(b.paidAmount, 0);
      expect(b.dueAmount, 66);
      expect(b.couponDiscount, 0);
      expect(b.payableAmount, 66);
    });

    test('doubles, and a partially paid series keeps its remainder', () {
      final b = MonthlyBookingResponse.fromJson(row({
        'total_amount': 264.0,
        'paid_amount': 66.5,
        'due_amount': 197.5,
      }));

      expect(b.totalAmount, 264.0);
      expect(b.paidAmount, 66.5);
      expect(b.dueAmount, 197.5);
    });
  });

  group('flags are read by meaning, not by one literal', () {
    test('1 / "1" / true all mean yes', () {
      for (final yes in <dynamic>[1, '1', true]) {
        final b = MonthlyBookingResponse.fromJson(
          row({'is_monthly': yes, 'is_monthly_active': yes, 'is_due_paid': yes}),
        );
        expect(b.isMonthly, isTrue, reason: 'is_monthly as $yes');
        expect(b.isMonthlyActive, isTrue, reason: 'is_monthly_active as $yes');
        expect(b.isDuePaid, isTrue, reason: 'is_due_paid as $yes');
      }
    });

    test('0 / "0" / false / null all mean no', () {
      for (final no in <dynamic>[0, '0', false, null]) {
        final b = MonthlyBookingResponse.fromJson(
          row({'is_monthly': no, 'is_monthly_active': no, 'is_due_paid': no}),
        );
        expect(b.isMonthly, isFalse, reason: 'is_monthly as $no');
        expect(b.isDuePaid, isFalse, reason: 'is_due_paid as $no');
      }
    });
  });

  group('missing pieces degrade instead of taking the screen down', () {
    test('a null branch name renders as empty, not as a crash', () {
      // branch_name arrives through a LEFT JOIN; a deleted branch row makes it
      // legitimately null.
      final b = MonthlyBookingResponse.fromJson(row({'branch_name': null}));

      expect(b.branchName, '');
      expect(b.id, 286);
    });

    test('an absent customer object yields a blank customer', () {
      final b = MonthlyBookingResponse.fromJson(row({'customer': null}));

      expect(b.customer.fullName, '');
      expect(b.customer.phoneNo, '');
      expect(b.customer.userId, isNull);
    });

    test('numeric identifiers sent as strings still read as numbers', () {
      final b = MonthlyBookingResponse.fromJson(row({
        'id': '286',
        'created_by': '38',
        'cmn_customer_id': '58',
        'service_bookings_all_count': '4',
      }));

      expect(b.id, 286);
      expect(b.createdBy, 38);
      expect(b.customerId, 58);
      expect(b.serviceBookingsAllCount, 4);
    });
  });

  group('the list envelope', () {
    test('parses a real two-row page', () {
      final list = MonthlyBookingListResponse.fromJson({
        'status': '1',
        'data': [
          row({'id': 286, 'total_amount': 66}),
          row({'id': 285, 'total_amount': '66.00'}),
        ],
      });

      expect(list.data.map((e) => e.id), [286, 285]);
      expect(list.data.every((e) => e.totalAmount == 66), isTrue);
    });

    test('an empty or absent data key is an empty list, not an exception', () {
      expect(
        MonthlyBookingListResponse.fromJson({'status': '1'}).data,
        isEmpty,
      );
      expect(
        MonthlyBookingListResponse.fromJson({'status': '1', 'data': []}).data,
        isEmpty,
      );
    });
  });
}
