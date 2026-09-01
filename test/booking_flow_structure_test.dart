import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural guarantees about the manager booking flow.
///
/// Two defects here were values read from the wrong place rather than logic
/// that computed a wrong answer, and the durable way to stop them coming back
/// is to assert those places are no longer read:
///
///   `focusedDay` — the operational NIGHT — became the booking's calendar
///   date, putting every after-midnight booking a day early and anchoring
///   monthly series on the wrong weekday.
///
///   «اختر الحجز» asked the manager to pick an internal `sch_employees` time
///   band before they could see a single time.
///
/// These fail the moment either is reintroduced.
void main() {
  final flow = File('lib/features/booking/presentation/view/add_booking.dart');
  final schedule = File(
      'lib/features/booking/presentation/view/widgets/night_schedule_section.dart');
  final cubit = File(
      'lib/features/booking/presentation/manager/calendar_cubit/calendar_cubit.dart');

  /// Comments explain these bugs on purpose; they are not the bugs.
  String code(File file) => file
      .readAsLinesSync()
      .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
      .join('\n');

  group('the booking flow', () {
    test('exists where these tests expect it', () {
      expect(flow.existsSync(), isTrue);
      expect(schedule.existsSync(), isTrue);
    });

    test('never reads focusedDay', () {
      expect(
        code(flow).contains('focusedDay'),
        isFalse,
        reason: 'the booking date must come from the server-selected slot, '
            'not from the operational night being browsed',
      );
    });

    test('derives every submitted value from the selected occurrence', () {
      final source = flow.readAsStringSync();

      expect(source, contains('BookingOccurrence'));
      expect(source, contains('slot.startAt'));
      expect(source, contains('slot.employeeId'),
          reason: 'the band that prices the slot travels with it');
    });

    test('has no fallback from a missing slot to a night', () {
      final source = code(flow);

      expect(source.contains('?? state.focusedDay'), isFalse);
      expect(source.contains('?? calendar.focusedDay'), isFalse);
      expect(source.contains('DateTime.now()'), isFalse,
          reason: 'a missing slot is a bug to surface, not a date to guess');
    });
  });

  group('the band picker', () {
    test('is gone from the flow', () {
      final source = flow.readAsStringSync();

      expect(source.contains('EmployeeSelection('), isFalse);
      expect(source.contains('EmployeeSelectionNew('), isFalse);
    });

    test('its widgets no longer exist', () {
      for (final path in const [
        'lib/features/booking/presentation/view/widgets/employee_selection.dart',
        'lib/features/home/presentation/view/widgets/employee_selection_new.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: '$path should be gone');
      }
    });

    test('no screen offers «حجز مسائي» or «بعد منتصف الليل» as a choice', () {
      // The phrase still appears as a HEADING on the schedule screen, which is
      // presentation. What must not exist is a step that asks for it.
      final source = code(schedule);

      expect(source.contains('setEmployeeId(emp'), isFalse);
      expect(source.contains('EmployeeCubit'), isFalse);
    });
  });

  group('the schedule screen', () {
    test('reads the merged-night endpoint, not the band-scoped one', () {
      final source = code(cubit);

      expect(source, contains('listNightSlots'));
      expect(source, contains('operationalDate: formattedDate'));
      expect(source.contains('listTimeslot'), isFalse);
    });

    test('never shifts or rebuilds a SLOT date', () {
      final source = code(cubit) + code(schedule);

      // Generating a forward date strip is fine — that is the night picker.
      // What must never happen is a slot's own moment being derived on the
      // device. The old code split the clock string and rebuilt a DateTime on
      // the browsed night's year/month/day:
      //
      //   DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
      //            int.parse(parts[0]), ...)
      //
      // which is precisely what put every after-midnight slot a day early.
      expect(source.contains('int.parse(parts['), isFalse);
      expect(source.contains('selectedDate.year'), isFalse);
      expect(source.contains('.split(\':\')'), isFalse,
          reason: 'a clock string is never parsed into a date here');

      // And nothing is added to or subtracted from a slot's own timestamps.
      expect(source.contains('startAt.add('), isFalse);
      expect(source.contains('startAt.subtract('), isFalse);
      expect(source.contains('endAt.add('), isFalse);
    });

    test('never fabricates a slot duration', () {
      final source = code(schedule) + code(cubit);

      expect(
        source.contains('Duration(hours: 1)'),
        isFalse,
        reason: "the server's end_at wins; a fixed hour rewrote any service "
            'that is not sixty minutes',
      );
    });

    test('asks the server whether the previous night is bookable', () {
      final source = code(schedule);

      expect(source, contains('loadPreviousNight'));
      expect(source, contains('_previousNight.operationalDate'),
          reason: 'the night comes from the server, verbatim');
    });
  });

  group('payment', () {
    test('defaults to the only supported method', () {
      final source = File(
        'lib/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('int _paymentType = 1;'),
        reason: 'it started at 0 — not a valid payment type id — so a manager '
            'who never tapped the single option was refused by a validation '
            'rule rather than told anything useful',
      );
    });
  });
}
