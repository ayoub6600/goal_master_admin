import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';

import 'support/monthly_fixtures.dart';

/// The list returns one row per SESSION, all pointing at one booking_series.
/// Rendered row by row, a four-week booking looked like four separate monthly
/// bookings — four cards, four totals, four cancel buttons.
void main() {
  group('grouping is done on the server id, never inferred', () {
    test('four sessions of one series become one booking', () {
      final groups = MonthlySeriesGroup.from([
        occurrence(id: 286, seriesId: 100002, seq: 4, date: '2026-09-20'),
        occurrence(id: 285, seriesId: 100002, seq: 3, date: '2026-09-13'),
        occurrence(id: 284, seriesId: 100002, seq: 2, date: '2026-09-06'),
        occurrence(id: 283, seriesId: 100002, seq: 1, date: '2026-08-30'),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.totalCount, 4);
      expect(groups.single.reference, 100002);
      expect(groups.single.isSeries, isTrue);
    });

    test('two series stay two bookings', () {
      final groups = MonthlySeriesGroup.from([
        occurrence(id: 286, seriesId: 100002, seq: 1, date: '2026-09-20'),
        occurrence(id: 281, seriesId: 100001, seq: 1, date: '2026-09-20'),
      ]);

      expect(groups, hasLength(2));
    });

    test('identical customer and slot do NOT merge without a series id', () {
      // Same person, same pitch, same hour, no series: two standalone
      // bookings. Merging them on similarity would invent a commitment the
      // customer never made.
      final groups = MonthlySeriesGroup.from([
        occurrence(id: 12, seriesId: 0, seq: 0, date: '2026-09-20'),
        occurrence(id: 13, seriesId: 0, seq: 0, date: '2026-09-27'),
      ]);

      expect(groups, hasLength(2));
      expect(groups.every((g) => g.isSeries), isFalse);
    });

    test('sessions are ordered by the day they are played', () {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30'),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06'),
      ]).single;

      expect(
        group.occurrences.map((o) => o.occurrenceDate),
        ['2026-08-30', '2026-09-06', '2026-09-13'],
      );
    });
  });

  group('the next session is deterministic', () {
    final series = MonthlySeriesGroup.from([
      occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30'),
      occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06'),
      occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
      occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
    ]).single;

    test('it is the earliest session not yet played', () {
      final next = series.nextOccurrence(DateTime(2026, 9, 8));

      expect(next!.occurrenceDate, '2026-09-13');
      expect(series.nextPosition(DateTime(2026, 9, 8)), 3);
    });

    test('a session happening today still counts as next', () {
      expect(
        series.nextOccurrence(DateTime(2026, 9, 13, 23, 59))!.occurrenceDate,
        '2026-09-13',
      );
    });

    test('a finished series reports none — never an old date', () {
      // The card says «آخر موعد» in this case. Labelling a past date as
      // upcoming would have a manager holding a pitch for a game that was
      // played weeks ago.
      expect(series.nextOccurrence(DateTime(2026, 10, 1)), isNull);
      expect(series.lastOccurrence!.occurrenceDate, '2026-09-20');
    });

    test('cancelled sessions are skipped over', () {
      final withCancellation = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-06'),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-13', status: 3),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-20'),
      ]).single;

      expect(
        withCancellation.nextOccurrence(DateTime(2026, 9, 10))!.occurrenceDate,
        '2026-09-20',
      );
    });

    test('the session date comes from `date`, not from the DATETIME', () {
      // start_time carries the series creation day in its date half. Reading
      // "next" from it would put every session of every series on one day.
      final group = MonthlySeriesGroup.from([
        occurrence(
          id: 1,
          seriesId: 7,
          seq: 1,
          date: '2026-09-20',
          startTime: '2026-08-30 20:00:00',
        ),
      ]).single;

      expect(group.nextOccurrence(DateTime(2026, 9, 1)), isNotNull);
      expect(group.nextOccurrence(DateTime(2026, 9, 25)), isNull);
    });
  });

  group('money is summed from the server rows', () {
    test('totals add up across the series and exclude cancellations', () {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', amount: 66, paid: 66),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06', amount: 66, paid: 34),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13', amount: 66),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20', amount: 66, status: 3),
      ]).single;

      expect(group.totalAmount, 198);
      expect(group.paidAmount, 100);
      expect(group.remainingAmount, 98);
      expect(group.paymentState, SeriesPaymentState.partial);
    });

    test('nothing received reads as unpaid', () {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-20', amount: 66),
      ]).single;

      expect(group.paymentState, SeriesPaymentState.unpaid);
      expect(group.remainingAmount, 66);
    });

    test('fully settled reads as خالص and never goes negative', () {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-20', amount: 66, paid: 70),
      ]).single;

      expect(group.paymentState, SeriesPaymentState.settled);
      expect(group.remainingAmount, 0);
    });
  });

  group('series state', () {
    test('progress counts only completed sessions', () {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', status: 4),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06', status: 4),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
      ]).single;

      expect(group.playedCount, 2);
      expect(group.totalCount, 4);
    });

    test('a replacement is reported only from the server flag', () {
      final flagged = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-06', replacement: true),
      ]).single;
      // A different clock time on its own is NOT a replacement.
      final justADifferentTime = MonthlySeriesGroup.from([
        occurrence(
          id: 2,
          seriesId: 8,
          seq: 1,
          date: '2026-09-06',
          startTime: '2026-08-30 22:00:00',
        ),
      ]).single;

      expect(flagged.hasReplacement, isTrue);
      expect(justADifferentTime.hasReplacement, isFalse);
    });

    test('a series whose sessions are all cancelled is not active', () {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-20', status: 3),
      ]).single;

      expect(group.isActive, isFalse);
    });
  });

  group('start_at is the authority, with fallbacks only when it is absent', () {
    test('a session reads its day AND clock from start_at', () {
      // start_time says 30 August; date says 20 September; start_at says
      // 20 September 20:00. Only start_at carries both, and it wins.
      final o = MonthlyBookingResponse.fromJson({
        'id': 1,
        'date': '2026-09-20',
        'occurrence_date': '2026-09-20',
        'start_time': '2026-08-30 20:00:00',
        'end_time': '2026-08-30 21:00:00',
        'start_at': '2026-09-20 20:00:00',
        'end_at': '2026-09-20 21:00:00',
        'booking_series_id': 7,
        'customer': const <String, dynamic>{},
      });

      expect(MonthlySeriesGroup.occurrenceStart(o), DateTime(2026, 9, 20, 20));
      expect(MonthlySeriesGroup.occurrenceEnd(o), DateTime(2026, 9, 20, 21));
      expect(MonthlySeriesGroup.occurrenceDate(o), DateTime(2026, 9, 20));
    });

    test('a moved session is followed to its new slot', () {
      // The whole point of reading the engine's own column: if an occurrence
      // is rescheduled, the screen must show where it went, not where the
      // recurrence pattern says it should be.
      final o = MonthlyBookingResponse.fromJson({
        'id': 1,
        'date': '2026-09-20',
        'start_time': '2026-08-30 20:00:00',
        'end_time': '2026-08-30 21:00:00',
        'start_at': '2026-09-22 16:30:00',
        'end_at': '2026-09-22 17:30:00',
        'booking_series_id': 7,
        'customer': const <String, dynamic>{},
      });

      expect(
        MonthlySeriesGroup.occurrenceStart(o),
        DateTime(2026, 9, 22, 16, 30),
      );
    });

    test('without start_at, the day comes from date and the clock from '
        'start_time', () {
      final o = MonthlyBookingResponse.fromJson({
        'id': 1,
        'date': '2026-09-20',
        'occurrence_date': '2026-09-20',
        'start_time': '2026-08-30 20:00:00',
        'end_time': '2026-08-30 21:00:00',
        'booking_series_id': 7,
        'customer': const <String, dynamic>{},
      });

      // The junk date on start_time is never used for the day.
      expect(MonthlySeriesGroup.occurrenceStart(o), DateTime(2026, 9, 20, 20));
    });

    test('a night crossing midnight ends on the next day', () {
      final o = MonthlyBookingResponse.fromJson({
        'id': 1,
        'date': '2026-09-20',
        'occurrence_date': '2026-09-20',
        'start_time': '23:00:00',
        'end_time': '00:00:00',
        'booking_series_id': 7,
        'customer': const <String, dynamic>{},
      });

      expect(MonthlySeriesGroup.occurrenceStart(o), DateTime(2026, 9, 20, 23));
      expect(MonthlySeriesGroup.occurrenceEnd(o), DateTime(2026, 9, 21, 0));
    });
  });

  test('the real payload from the server groups into one booking', () {
    final rows = (realMonthlyPayload['data'] as List)
        .map((e) => MonthlyBookingResponse.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    final groups = MonthlySeriesGroup.from(rows);

    expect(groups, hasLength(1));
    expect(groups.single.totalCount, 4);
    expect(groups.single.customerName, 'ayoubbelhaj');
    expect(groups.single.hasReplacement, isTrue);
  });
}
