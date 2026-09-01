import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';
import 'package:goal_master_admin/features/booking/domain/booking_payment.dart';

/// The status and the paid amount can no longer disagree.
///
/// They used to be independent controls sitting beside each other: two status
/// buttons and a free-text amount. A booking could be marked «خالص» with 0
/// recorded, or «موافَق عليه» with the full amount typed in — and switching
/// status left whatever had been typed before still in the field.
///
/// The amount is now derived from the status and the server's total every time
/// it is read, never stored, so there is no value that can go stale.
void main() {
  const approved = BookingPaymentStatus.approved;
  const paid = BookingPaymentStatus.paid;

  group('the default state of the confirmation screen', () {
    test('«موافَق عليه» records nothing collected', () {
      expect(
        BookingPaymentStatus.paidAmountFor(status: approved, total: 66),
        0,
      );
    });

    test('the screen opens on «موافَق عليه»', () {
      // What initState sets. Named here so a change to the default has to
      // change this test too.
      expect(BookingPaymentStatus.options.first, approved);
    });

    test('an unset status is treated as nothing collected', () {
      expect(BookingPaymentStatus.paidAmountFor(status: null, total: 66), 0);
    });
  });

  group('«خالص»', () {
    test('records the full booking total without anything being typed', () {
      expect(BookingPaymentStatus.paidAmountFor(status: paid, total: 66), 66);
    });

    test('records the full monthly total', () {
      expect(BookingPaymentStatus.paidAmountFor(status: paid, total: 264), 264);
    });

    test('never records a payment when there is no price to pay', () {
      expect(BookingPaymentStatus.paidAmountFor(status: paid, total: 0), 0);
      expect(BookingPaymentStatus.paidAmountFor(status: paid, total: -5), 0);
    });
  });

  group('switching status', () {
    test('0 → total → 0 → total, with nothing surviving in between', () {
      const total = 66.0;

      final sequence = [approved, paid, approved, paid]
          .map((s) => BookingPaymentStatus.paidAmountFor(status: s, total: total))
          .toList();

      expect(sequence, [0, 66, 0, 66]);
    });

    test('a long run of switches never leaves a stale amount', () {
      const total = 264.0;
      var status = approved;

      for (var i = 0; i < 12; i++) {
        status = status == approved ? paid : approved;

        expect(
          BookingPaymentStatus.paidAmountFor(status: status, total: total),
          status == paid ? total : 0,
          reason: 'switch #$i produced the wrong amount',
        );
      }
    });
  });

  group('the payload', () {
    test('sends a plain whole number for a whole-dinar total', () {
      expect(
        BookingPaymentStatus.paidAmountStringFor(status: paid, total: 66),
        '66',
      );
      expect(
        BookingPaymentStatus.paidAmountStringFor(status: approved, total: 66),
        '0',
      );
    });

    test('keeps the fractional part when the venue prices in halves', () {
      expect(
        BookingPaymentStatus.paidAmountStringFor(status: paid, total: 66.5),
        '66.50',
      );
    });
  });

  // ---------- the monthly total is the resolved one ----------

  group('a monthly booking', () {
    Map<String, dynamic> row({
      required String date,
      double price = 66,
      bool available = true,
    }) =>
        {
          'sequence': 1,
          'date': date,
          'start_time': '18:00:00',
          'end_time': '19:00:00',
          'start_at': '$date 18:00:00',
          'end_at': '$date 19:00:00',
          'employee_id': 11,
          'price': price,
          'available': available,
          'action': available ? 'book' : 'block',
          'can_replace': !available,
          'replacement_options': available
              ? null
              : {
                  'same_day': [
                    {
                      'date': date,
                      'start_time': '20:00:00',
                      'end_time': '21:00:00',
                      'start_at': '$date 20:00:00',
                      'end_at': '$date 21:00:00',
                      'employee_id': 12,
                      // A different band, priced higher.
                      'price': 90,
                      'same_day': true,
                    }
                  ],
                  'nearby_days': const [],
                  'enabled': true,
                },
        };

    SeriesPreview preview(List<Map<String, dynamic>> rows) =>
        SeriesPreview.fromJson({
          'dates': rows,
          'all_available': rows.every((r) => r['available'] == true),
          'satisfiable': true,
          'plan_signature': 'sig',
          'target_occurrence_count': 4,
          'price_per_occurrence': 66,
          'total_amount': 264,
          'resolved_total_amount': 264,
          'final_occurrence_count': rows.length,
          'replacement_enabled': true,
        });

    test('«خالص» records the plan total, not one appointment', () {
      final plan = preview([
        row(date: '2026-08-30'),
        row(date: '2026-09-06'),
        row(date: '2026-09-13'),
        row(date: '2026-09-20'),
      ]);

      expect(plan.displayTotal, 264);
      expect(
        BookingPaymentStatus.paidAmountFor(status: paid, total: plan.displayTotal),
        264,
      );
    });

    test('moving an appointment into a dearer band raises what «خالص» records',
        () {
      final plan = preview([
        row(date: '2026-08-30'),
        row(date: '2026-09-06', available: false),
        row(date: '2026-09-13'),
        row(date: '2026-09-20'),
      ]);

      final resolved = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06'
                ? d.copyWith(
                    chosenReplacement: d.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );

      // 66 + 90 + 66 + 66.
      expect(resolved.displayTotal, 288);
      expect(
        BookingPaymentStatus.paidAmountFor(
            status: paid, total: resolved.displayTotal),
        288,
        reason: 'the recorded payment follows the FINAL resolved total',
      );
    });

    test('a move leaves «موافَق عليه» at nothing collected', () {
      final plan = preview([
        row(date: '2026-08-30'),
        row(date: '2026-09-06', available: false),
        row(date: '2026-09-13'),
        row(date: '2026-09-20'),
      ]);

      final resolved = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06'
                ? d.copyWith(
                    chosenReplacement: d.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );

      expect(resolved.displayTotal, 288);
      expect(
        BookingPaymentStatus.paidAmountFor(
            status: approved, total: resolved.displayTotal),
        0,
      );
    });

    test('a plan still loading records nothing, whatever the status', () {
      // There is no total yet, so «خالص» must not record a figure it invented.
      expect(BookingPaymentStatus.paidAmountFor(status: paid, total: 0), 0);
      expect(BookingPaymentStatus.paidAmountFor(status: approved, total: 0), 0);
    });
  });
  paymentSelectionContract();
}

/// «غير مدفوع» / «مدفوع جزئي» / «خالص».
///
/// Partial payment is what a venue actually takes half the time — a deposit
/// now, the rest on the night — and the manager app had no way to record it.
/// The booking's lifecycle status is Approved in all three cases.
void paymentSelectionContract() {
  const total = 66.0;

  group('the three payment states', () {
    test('unpaid records nothing', () {
      expect(PaymentSelection.unpaid.amountFor(total), 0);
    });

    test('paid records the whole total without anything being typed', () {
      expect(PaymentSelection.paid.amountFor(total), 66);
    });

    test('partial records what the manager typed', () {
      expect(PaymentSelection.partial.amountFor(total, entered: 30), 30);
    });

    test('a partial amount can never exceed the booking', () {
      expect(PaymentSelection.partial.amountFor(total, entered: 100), 66);
    });

    test('a negative partial amount records nothing', () {
      expect(PaymentSelection.partial.amountFor(total, entered: -5), 0);
    });
  });

  group('an amount implies a state', () {
    test('nothing paid is unpaid', () {
      expect(PaymentSelection.forAmount(0, total), PaymentSelection.unpaid);
    });

    test('some paid is partial', () {
      expect(PaymentSelection.forAmount(30, total), PaymentSelection.partial);
    });

    test('all paid is paid, not partial', () {
      expect(PaymentSelection.forAmount(66, total), PaymentSelection.paid);
    });
  });

  group('switching between states', () {
    test('leaves no stale amount behind', () {
      // The manager types 30, switches to خالص, then back to غير مدفوع.
      final sequence = [
        PaymentSelection.partial.amountFor(total, entered: 30),
        PaymentSelection.paid.amountFor(total),
        PaymentSelection.unpaid.amountFor(total),
        PaymentSelection.partial.amountFor(total, entered: 20),
      ];

      expect(sequence, [30, 66, 0, 20]);
    });
  });

  group('a monthly total', () {
    test('partial records a deposit against the whole series', () {
      expect(PaymentSelection.partial.amountFor(264, entered: 100), 100);
      expect(PaymentSelection.paid.amountFor(264), 264);
      expect(PaymentSelection.unpaid.amountFor(264), 0);
    });

    test('a replacement that raises the total raises what خالص records', () {
      expect(PaymentSelection.paid.amountFor(288), 288);
    });
  });

  test('the lifecycle status is Approved whatever was paid', () {
    // Never ServiceStatus::Done — that says the match was played.
    expect(BookingPaymentStatus.lifecycleApproved, '2');
    expect(BookingPaymentStatus.lifecycleApproved, isNot('4'));
  });
}
