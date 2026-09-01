import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';

/// The recurring-booking plan a manager sees before confirming.
///
/// The rules that matter and are easy to get wrong:
///
///   Moving a taken week REPLACES that week. Four appointments before a move,
///   four after — never four plus an extra "backup" booking.
///
///   The total is summed from the appointments that will actually be created,
///   so a move into a differently priced band changes it. Never first week's
///   price times four.
///
///   Confirm stays blocked while any week is still taken.
void main() {
  Map<String, dynamic> row({
    required int sequence,
    required String date,
    required String start,
    required String end,
    bool available = true,
    double price = 66,
    int employeeId = 11,
    bool canReplace = false,
    List<Map<String, dynamic>> sameDay = const [],
  }) {
    return {
      'sequence': sequence,
      'week_index': sequence - 1,
      'date': date,
      'start_time': start,
      'end_time': end,
      'start_at': '$date $start',
      'end_at': '$date $end',
      'employee_id': employeeId,
      'price': price,
      'available': available,
      'action': available ? 'book' : 'block',
      'is_extension': false,
      'is_replacement': false,
      'original_date': null,
      'can_replace': canReplace,
      'message': available ? null : 'هذا الموعد محجوز',
      'replacement_options': canReplace
          ? {
              'same_day': sameDay,
              'nearby_days': const [],
              'window_days': 2,
              'enabled': true,
            }
          : null,
    };
  }

  Map<String, dynamic> option({
    required String date,
    required String start,
    required String end,
    double price = 66,
    int employeeId = 11,
  }) {
    return {
      'date': date,
      'start_time': start,
      'end_time': end,
      'start_at': '$date $start',
      'end_at': '$date $end',
      'employee_id': employeeId,
      'price': price,
      'same_day': true,
      'day_distance': 0,
      'available': true,
    };
  }

  SeriesPreview preview(List<Map<String, dynamic>> rows, {double resolved = 264}) {
    return SeriesPreview.fromJson({
      'dates': rows,
      'all_available': rows.every((r) => r['available'] == true),
      'satisfiable': true,
      'plan_signature': 'sig-1',
      'target_occurrence_count': 4,
      'price_per_occurrence': 66,
      'total_amount': 264,
      'resolved_total_amount': resolved,
      'final_occurrence_count': rows.length,
      'replacement_enabled': true,
    });
  }

  /// The all-clear plan: Sunday 30 August at 18:00, four weeks.
  SeriesPreview cleanPlan() => preview([
        row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        row(sequence: 2, date: '2026-09-06', start: '18:00:00', end: '19:00:00'),
        row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
        row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
      ]);

  /// The same plan with week 2 taken, and 19:00 free that evening.
  SeriesPreview oneConflictPlan() => preview([
        row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        row(
          sequence: 2,
          date: '2026-09-06',
          start: '18:00:00',
          end: '19:00:00',
          available: false,
          canReplace: true,
          sameDay: [option(date: '2026-09-06', start: '19:00:00', end: '20:00:00')],
        ),
        row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
        row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
      ]);

  // ---------- 1-2: the plan loads ----------

  group('an all-available plan', () {
    test('describes four appointments on consecutive Sundays', () {
      final plan = cleanPlan();

      expect(plan.dates.length, 4);
      expect(plan.plannedOccurrences.length, 4);
      expect(
        plan.dates.map((d) => d.date),
        ['2026-08-30', '2026-09-06', '2026-09-13', '2026-09-20'],
      );
      expect(
        plan.dates.every((d) => d.startAt!.weekday == DateTime.sunday),
        isTrue,
      );
    });

    test('is ready to confirm', () {
      final plan = cleanPlan();

      expect(plan.allAvailable, isTrue);
      expect(plan.hasUnresolved, isFalse);
      expect(plan.isReadyToConfirm, isTrue);
    });

    test('each row carries its own authoritative moment, band and price', () {
      final first = cleanPlan().dates.first;

      expect(first.startAt, DateTime(2026, 8, 30, 18));
      expect(first.endAt, DateTime(2026, 8, 30, 19));
      expect(first.employeeId, 11);
      expect(first.price, 66);
    });
  });

  // ---------- 3-5: conflicts block confirmation ----------

  group('a plan with one taken week', () {
    test('names exactly that week', () {
      final plan = oneConflictPlan();

      expect(plan.unresolved.length, 1);
      expect(plan.unresolved.single.date, '2026-09-06');
      expect(plan.unresolved.single.canReplace, isTrue);
    });

    test('cannot be confirmed', () {
      expect(oneConflictPlan().isReadyToConfirm, isFalse);
    });

    test('offers the alternatives the server generated', () {
      final blocked = oneConflictPlan().unresolved.single;
      final options = blocked.replacementOptions!;

      expect(options.hasAny, isTrue);
      expect(options.sameDay.single.startAt, DateTime(2026, 9, 6, 19));
    });
  });

  group('a plan with two taken weeks', () {
    SeriesPreview twoConflicts() => preview([
          row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
          row(
            sequence: 2,
            date: '2026-09-06',
            start: '18:00:00',
            end: '19:00:00',
            available: false,
            canReplace: true,
            sameDay: [option(date: '2026-09-06', start: '19:00:00', end: '20:00:00')],
          ),
          row(
            sequence: 3,
            date: '2026-09-13',
            start: '18:00:00',
            end: '19:00:00',
            available: false,
            canReplace: true,
            sameDay: [option(date: '2026-09-13', start: '20:00:00', end: '21:00:00')],
          ),
          row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
        ]);

    test('reports both, then one, then none', () {
      var plan = twoConflicts();
      expect(plan.unresolved.length, 2);

      // Resolve the first.
      plan = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06'
                ? d.copyWith(
                    chosenReplacement: d.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );
      expect(plan.unresolved.length, 1);
      expect(plan.isReadyToConfirm, isFalse);

      // Resolve the second.
      plan = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-13'
                ? d.copyWith(
                    chosenReplacement: d.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );
      expect(plan.unresolved, isEmpty);
      expect(plan.isReadyToConfirm, isTrue);
    });

    test('two moves still leave exactly four appointments', () {
      var plan = twoConflicts();

      for (final date in ['2026-09-06', '2026-09-13']) {
        plan = plan.copyWith(
          dates: plan.dates
              .map((d) => d.date == date
                  ? d.copyWith(
                      chosenReplacement: d.replacementOptions!.sameDay.single)
                  : d)
              .toList(),
        );
      }

      expect(plan.plannedOccurrences.length, 4);
      expect(plan.dates.length, 4, reason: 'a move never adds a row');
    });
  });

  // ---------- 6-13: a move is a move ----------

  group('moving one appointment', () {
    SeriesPreview moved() {
      final plan = oneConflictPlan();
      final blocked = plan.dates.firstWhere((d) => d.date == '2026-09-06');

      return plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06'
                ? d.copyWith(
                    chosenReplacement: blocked.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );
    }

    test('keeps the series at four', () {
      expect(moved().plannedOccurrences.length, 4);
      expect(moved().dates.length, 4);
    });

    test('replaces the position rather than adding one', () {
      final plan = moved();
      final row = plan.dates.firstWhere((d) => d.date == '2026-09-06');

      expect(row.isReplaced, isTrue);
      // One row for 6 September, not two.
      expect(plan.dates.where((d) => d.date == '2026-09-06').length, 1);
    });

    test('the payload keys the move to the position it replaces', () {
      final row = moved().dates.firstWhere((d) => d.date == '2026-09-06');
      final json = row.toReplacementJson()!;

      expect(json['original_date'], '2026-09-06',
          reason: 'this is what makes it a move and not a new booking');
      expect(json['date'], '2026-09-06');
      expect(json['start_time'], '19:00:00');
    });

    test('keeps the band and the authoritative datetimes of the new slot', () {
      final row = moved().dates.firstWhere((d) => d.date == '2026-09-06');

      expect(row.chosenReplacement!.employeeId, 11);
      expect(row.effectiveStartAt, DateTime(2026, 9, 6, 19));
      expect(row.effectiveEndAt, DateTime(2026, 9, 6, 20));
      // The untouched weeks are unaffected.
      expect(
        moved().dates.first.effectiveStartAt,
        DateTime(2026, 8, 30, 18),
      );
    });

    test('undoing it puts the conflict back', () {
      final plan = moved();
      final undone = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06' ? d.copyWith(clearChoice: true) : d)
            .toList(),
      );

      expect(undone.unresolved.length, 1);
      expect(undone.isReadyToConfirm, isFalse);
    });
  });

  // ---------- 14: pricing follows the resolved plan ----------

  group('the total', () {
    test('is four times the fee when every appointment costs the same', () {
      expect(cleanPlan().displayTotal, 264);
    });

    test('recalculates when a move lands in a differently priced band', () {
      final plan = preview([
        row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        row(
          sequence: 2,
          date: '2026-09-06',
          start: '18:00:00',
          end: '19:00:00',
          available: false,
          canReplace: true,
          // A later slot in the after-midnight band, priced higher.
          sameDay: [
            option(
              date: '2026-09-07',
              start: '00:00:00',
              end: '01:00:00',
              price: 90,
              employeeId: 12,
            )
          ],
        ),
        row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
        row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
      ]);

      final resolved = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06'
                ? d.copyWith(
                    chosenReplacement: d.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );

      // 66 + 90 + 66 + 66, not 66 × 4.
      expect(resolved.displayTotal, 288);
      expect(resolved.plannedOccurrences.length, 4);
    });
  });

  // ---------- 15-17: midnight and month boundaries ----------

  group('a midnight series', () {
    /// Anchored on Sunday 30 August 00:00, which belongs to the operational
    /// night of Saturday 29 August. The recurrence follows the APPOINTMENT.
    SeriesPreview midnightPlan() => preview([
          row(sequence: 1, date: '2026-08-30', start: '00:00:00', end: '01:00:00'),
          row(
            sequence: 2,
            date: '2026-09-06',
            start: '00:00:00',
            end: '01:00:00',
            available: false,
            canReplace: true,
            sameDay: [option(date: '2026-09-06', start: '01:00:00', end: '02:00:00')],
          ),
          row(sequence: 3, date: '2026-09-13', start: '00:00:00', end: '01:00:00'),
          row(sequence: 4, date: '2026-09-20', start: '00:00:00', end: '01:00:00'),
        ]);

    test('recurs on Sundays, never on the Saturday night it belongs to', () {
      final plan = midnightPlan();

      expect(
        plan.dates.map((d) => d.date),
        ['2026-08-30', '2026-09-06', '2026-09-13', '2026-09-20'],
      );
      expect(plan.dates.every((d) => d.startAt!.weekday == DateTime.sunday), isTrue);
      expect(plan.dates.any((d) => d.date == '2026-08-29'), isFalse);
    });

    test('a midnight week moves to 01:00 on the same day', () {
      final plan = midnightPlan();
      final blocked = plan.dates.firstWhere((d) => d.date == '2026-09-06');

      final resolved = plan.copyWith(
        dates: plan.dates
            .map((d) => d.date == '2026-09-06'
                ? d.copyWith(
                    chosenReplacement: blocked.replacementOptions!.sameDay.single)
                : d)
            .toList(),
      );

      final row = resolved.dates.firstWhere((d) => d.date == '2026-09-06');

      expect(row.effectiveStartAt, DateTime(2026, 9, 6, 1));
      expect(row.effectiveEndAt, DateTime(2026, 9, 6, 2));
      expect(resolved.plannedOccurrences.length, 4);
      expect(resolved.isReadyToConfirm, isTrue);
    });

    test('crosses the month boundary without drifting', () {
      final plan = midnightPlan();

      expect(plan.dates.last.startAt!.month, 9);
      expect(plan.dates.last.startAt!.day, 20);
      expect(plan.dates.last.startAt!.hour, 0);
    });
  });

  // ---------- 18-19: a plan the server cannot satisfy ----------

  group('an unsatisfiable plan', () {
    test('cannot be confirmed and says so', () {
      final plan = SeriesPreview.fromJson({
        'dates': const [],
        'all_available': false,
        'satisfiable': false,
        'plan_signature': '',
        'target_occurrence_count': 4,
      });

      expect(plan.satisfiable, isFalse);
      expect(plan.isReadyToConfirm, isFalse);
    });

    test('a plan short of the target cannot be confirmed', () {
      // Three positions where four were asked for: partial creation is not an
      // outcome this flow may reach.
      final plan = preview([
        row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        row(sequence: 2, date: '2026-09-06', start: '18:00:00', end: '19:00:00'),
        row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
      ]);

      expect(plan.plannedOccurrences.length, 3);
      expect(plan.isReadyToConfirm, isFalse);
    });
  });
}
