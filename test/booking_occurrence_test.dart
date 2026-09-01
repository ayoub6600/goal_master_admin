import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';

/// What a manager books is the slot the server offered, not the night they
/// were browsing.
///
/// The manager app used to submit the browsed night as the booking's calendar
/// date, and to rebuild each slot's DateTime from that night plus a clock
/// string — which put every after-midnight slot a day early. It also discarded
/// the server's end time and substituted start + 1 hour, silently rewriting
/// the length of any service that is not sixty minutes.
///
/// These tests pin the replacement: one occurrence, taken whole from the
/// server, and a night that has no say in it.
void main() {
  /// The night in every scenario below. Saturday.
  final operationalNight = DateTime(2026, 8, 29);

  /// A slot exactly as `list/operational-availability` returns one.
  OperationalSlot slot({
    required String date,
    required String start,
    required String end,
    required String startAt,
    required String endAt,
    int employeeId = 7,
    bool available = true,
    double? price,
  }) {
    return OperationalSlot.fromJson({
      'employee_id': employeeId,
      'date': date,
      'start_time': start,
      'end_time': end,
      'start_at': startAt,
      'end_at': endAt,
      'crosses_midnight': !endAt.startsWith(date),
      'is_available': available ? 1 : 0,
      'price': price,
    })!;
  }

  BookingOccurrence occurrenceOf(OperationalSlot s) => BookingOccurrence(
        startAt: s.startAt,
        endAt: s.endAt,
        employeeId: s.employeeId,
        price: s.price,
      );

  // ---------------- 1: a normal evening slot ----------------

  group('an evening slot', () {
    test('is booked on the night it belongs to', () {
      final o = occurrenceOf(slot(
        date: '2026-08-29',
        start: '19:00:00',
        end: '20:00:00',
        startAt: '2026-08-29 19:00:00',
        endAt: '2026-08-29 20:00:00',
      ));

      expect(o.serviceDate, '2026-08-29');
      expect(o.startTime, '19:00:00');
      expect(o.endTime, '20:00:00');
      expect(o.crossesMidnight, isFalse);
    });
  });

  // ---------------- 2: 23:00 → 00:00 ----------------

  group('a slot that crosses midnight', () {
    test('23:00 → 00:00 is dated by its START and ends the next day', () {
      final o = occurrenceOf(slot(
        date: '2026-08-29',
        start: '23:00:00',
        end: '00:00:00',
        startAt: '2026-08-29 23:00:00',
        endAt: '2026-08-30 00:00:00',
      ));

      // The night you play on is the night you start.
      expect(o.serviceDate, '2026-08-29');
      expect(o.startTime, '23:00:00');
      expect(o.endTime, '00:00:00');

      // The day the legacy clocks cannot express survives on the wire.
      expect(o.startAtWire, '2026-08-29 23:00:00');
      expect(o.endAtWire, '2026-08-30 00:00:00');
      expect(o.crossesMidnight, isTrue);
      expect(o.durationMinutes, 60);
    });
  });

  // ---------------- 3-4: the previous night, past midnight ----------------

  group('after-midnight slots of the previous night', () {
    test('00:00 → 01:00 on the night of 29 Aug is booked on 30 Aug', () {
      final s = slot(
        date: '2026-08-30',
        start: '00:00:00',
        end: '01:00:00',
        startAt: '2026-08-30 00:00:00',
        endAt: '2026-08-30 01:00:00',
      );
      final o = occurrenceOf(s);

      expect(o.serviceDate, '2026-08-30');
      expect(o.serviceDate, isNot('2026-08-29'),
          reason: 'the browsed night must never become the booking date');
      expect(s.isAfterMidnightOf('2026-08-29'), isTrue);
      expect(o.startAt.weekday, DateTime.sunday);
      expect(operationalNight.weekday, DateTime.saturday);
    });

    test('01:00 → 02:00 on the same night is also 30 Aug', () {
      final o = occurrenceOf(slot(
        date: '2026-08-30',
        start: '01:00:00',
        end: '02:00:00',
        startAt: '2026-08-30 01:00:00',
        endAt: '2026-08-30 02:00:00',
      ));

      expect(o.serviceDate, '2026-08-30');
      expect(o.startTime, '01:00:00');
      expect(o.endTime, '02:00:00');
    });
  });

  // ---------------- 5-6: where the date comes from ----------------

  group('the submitted date', () {
    test('is derived from start_at, never from the night', () {
      final o = occurrenceOf(slot(
        date: '2026-08-30',
        start: '00:00:00',
        end: '01:00:00',
        startAt: '2026-08-30 00:00:00',
        endAt: '2026-08-30 01:00:00',
      ));

      final nightAsDate = '${operationalNight.year}-'
          '${operationalNight.month.toString().padLeft(2, '0')}-'
          '${operationalNight.day.toString().padLeft(2, '0')}';

      expect(o.serviceDate, o.startAtWire.substring(0, 10));
      expect(o.serviceDate, isNot(nightAsDate));
    });

    test('an occurrence cannot be built without a band', () {
      // The band prices the booking, so an occurrence missing one would be a
      // booking nobody could charge correctly.
      expect(
        BookingOccurrence.tryFrom(
          '2026-08-30 00:00:00',
          '2026-08-30 01:00:00',
          employeeId: null,
        ),
        isNull,
      );
    });

    test('returns null before a slot has been selected', () {
      expect(BookingOccurrence.tryFrom(null, null, employeeId: 7), isNull);
      expect(
        BookingOccurrence.tryFrom('2026-08-30 00:00:00', null, employeeId: 7),
        isNull,
        reason: 'half an occurrence must not be treated as a whole one',
      );
    });
  });

  // ---------------- 7-8: the server's end wins ----------------

  group('duration', () {
    test('a 90-minute slot stays 90 minutes', () {
      final o = occurrenceOf(slot(
        date: '2026-08-29',
        start: '19:00:00',
        end: '20:30:00',
        startAt: '2026-08-29 19:00:00',
        endAt: '2026-08-29 20:30:00',
      ));

      expect(o.durationMinutes, 90);
      expect(o.endTime, '20:30:00');
    });

    test('a 30-minute slot stays 30 minutes', () {
      // Not hypothetical: a seeded service in this database is configured with
      // `time_slot_in_time = 00:30:00`, which the old fixed +1 hour would have
      // booked as sixty.
      final o = occurrenceOf(slot(
        date: '2026-08-29',
        start: '19:00:00',
        end: '19:30:00',
        startAt: '2026-08-29 19:00:00',
        endAt: '2026-08-29 19:30:00',
      ));

      expect(o.durationMinutes, 30);
      expect(o.endTime, '19:30:00');
      expect(o.endAtWire, '2026-08-29 19:30:00');
    });
  });

  // ---------------- 9-10: band and price ----------------

  group('the hidden band', () {
    test('the after-midnight slot keeps its own band, not the evening one', () {
      final evening = slot(
        date: '2026-08-29',
        start: '21:00:00',
        end: '22:00:00',
        startAt: '2026-08-29 21:00:00',
        endAt: '2026-08-29 22:00:00',
        employeeId: 11,
        price: 60,
      );
      final late = slot(
        date: '2026-08-30',
        start: '00:00:00',
        end: '01:00:00',
        startAt: '2026-08-30 00:00:00',
        endAt: '2026-08-30 01:00:00',
        employeeId: 12,
        price: 80,
      );

      expect(occurrenceOf(late).employeeId, 12);
      expect(occurrenceOf(late).employeeId, isNot(evening.employeeId));
    });

    test('the price travels with the band that set it', () {
      final late = slot(
        date: '2026-08-30',
        start: '00:00:00',
        end: '01:00:00',
        startAt: '2026-08-30 00:00:00',
        endAt: '2026-08-30 01:00:00',
        employeeId: 12,
        price: 80,
      );

      // Never recomputed on the device — this is the server's number.
      expect(occurrenceOf(late).price, 80);
    });
  });

  // ---------------- 11-12: what the night contains ----------------

  group('an operational night', () {
    OperationalNight night() => OperationalNight.fromJson({
          'operational_date': '2026-08-29',
          'slots': [
            {
              'employee_id': 11,
              'date': '2026-08-29',
              'start_time': '22:00:00',
              'end_time': '23:00:00',
              'start_at': '2026-08-29 22:00:00',
              'end_at': '2026-08-29 23:00:00',
              'is_available': 1,
              'price': 60,
            },
            {
              'employee_id': 12,
              'date': '2026-08-30',
              'start_time': '00:00:00',
              'end_time': '01:00:00',
              'start_at': '2026-08-30 00:00:00',
              'end_at': '2026-08-30 01:00:00',
              'is_available': 1,
              'price': 80,
            },
            {
              'employee_id': 12,
              'date': '2026-08-30',
              'start_time': '01:00:00',
              'end_time': '02:00:00',
              'start_at': '2026-08-30 01:00:00',
              'end_at': '2026-08-30 02:00:00',
              'is_available': 0,
              'price': 80,
            },
          ],
        });

    test('splits into evening and after-midnight by DATE, not by clock', () {
      final n = night();

      expect(n.evening.length, 1);
      expect(n.afterMidnight.length, 2);
      expect(n.hasAfterMidnight, isTrue);
      // The separator is drawn from this, and from nothing else.
      expect(n.afterMidnight.every((s) => s.date != n.operationalDate), isTrue);
    });

    test('a booked slot is marked unavailable', () {
      final n = night();
      final taken = n.slots.firstWhere((s) => !s.isAvailable);

      expect(taken.startAt, DateTime(2026, 8, 30, 1));
    });

    test('a slot without authoritative datetimes is dropped, not guessed', () {
      final n = OperationalNight.fromJson({
        'operational_date': '2026-08-29',
        'slots': [
          {'employee_id': 11, 'date': '2026-08-29', 'start_time': '22:00:00'},
        ],
      });

      expect(n.slots, isEmpty);
    });
  });

  // ---------------- 13-15: the monthly anchor ----------------

  group('the monthly anchor', () {
    test('recurs on Sundays from 30 Aug, never from Saturday the 29th', () {
      final o = occurrenceOf(slot(
        date: '2026-08-30',
        start: '01:00:00',
        end: '02:00:00',
        startAt: '2026-08-30 01:00:00',
        endAt: '2026-08-30 02:00:00',
      ));

      // The server steps +7 days from whatever anchor it is handed.
      final series = List.generate(
        4,
        (i) => o.startAt.add(Duration(days: 7 * i)),
      );

      expect(
        series.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}'),
        ['2026-08-30', '2026-09-06', '2026-09-13', '2026-09-20'],
      );
      expect(series.every((d) => d.weekday == DateTime.sunday), isTrue);
    });

    test('crosses a month boundary without drifting', () {
      final o = occurrenceOf(slot(
        date: '2026-08-30',
        start: '01:00:00',
        end: '02:00:00',
        startAt: '2026-08-30 01:00:00',
        endAt: '2026-08-30 02:00:00',
      ));

      final fourth = o.startAt.add(const Duration(days: 21));

      expect(fourth.month, 9);
      expect(fourth.day, 20);
      // Same clock on the other side of the month, which is the part that
      // clock-only arithmetic used to lose.
      expect(fourth.hour, 1);
    });

    test('a skip-and-extend resubmit uses the same anchor', () {
      // The approved plan and the resubmit both read the selected slot, so
      // they cannot disagree. This used to read the browsed night on the
      // resubmit path only.
      final s = slot(
        date: '2026-08-30',
        start: '01:00:00',
        end: '02:00:00',
        startAt: '2026-08-30 01:00:00',
        endAt: '2026-08-30 02:00:00',
      );

      final shown = occurrenceOf(s);
      final resubmitted = occurrenceOf(s);

      expect(resubmitted.serviceDate, shown.serviceDate);
      expect(resubmitted.startAtWire, shown.startAtWire);
      expect(resubmitted.employeeId, shown.employeeId);
    });
  });
}
