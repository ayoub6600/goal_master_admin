import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_setup/domain/opening_hours.dart';

/// A pitch owner knows one thing: "I open at five and close at three."
///
/// The engine needs that same night stored as two bands, because it decides
/// which night a 1am booking belongs to by finding a band whose window sits
/// wholly in the small hours. These tests pin the translation in both
/// directions, so the manager never meets the split and the engine never
/// stops seeing it.
void main() {
  const evening = TimeOfDay(hour: 17, minute: 0);

  group('a night that runs past midnight', () {
    const night = OpeningHours(
      opensAt: evening,
      closesAt: TimeOfDay(hour: 3, minute: 0),
    );

    test('is recognised as crossing midnight', () {
      expect(night.crossesMidnight, isTrue);
      expect(night.durationMinutes, 10 * 60);
      expect(night.isValid, isTrue);
    });

    test('splits into exactly the two bands the engine expects', () {
      // The evening ends at the sentinel, not at 23:00, so the last hour
      // before midnight is not lost in a gap between the bands.
      expect(night.eveningWindow, ('17:00:00', '24:00:00'));
      expect(night.afterMidnightWindow, ('00:00:00', '03:00:00'));
      expect(night.needsAfterMidnight, isTrue);
    });

    test('folds back from the stored bands unchanged', () {
      final loaded = OpeningHours.fromBands(
        eveningStart: '17:00:00',
        eveningEnd: '24:00:00',
        afterMidnightEnd: '03:00:00',
        afterMidnightEnabled: true,
      );

      expect(loaded, night);
      expect(loaded.opensAt.hour, 17);
      expect(loaded.closesAt.hour, 3);
    });
  });

  group('a venue that shuts by midnight', () {
    test('closing at 11pm keeps everything in the evening band', () {
      const early = OpeningHours(
        opensAt: evening,
        closesAt: TimeOfDay(hour: 23, minute: 0),
      );

      expect(early.crossesMidnight, isFalse);
      expect(early.eveningWindow, ('17:00:00', '23:00:00'));
      // Nothing after midnight, so that band is simply switched off.
      expect(early.afterMidnightWindow, isNull);
      expect(early.durationMinutes, 6 * 60);
    });

    test('closing exactly at midnight needs no second band', () {
      const toMidnight = OpeningHours(
        opensAt: evening,
        closesAt: TimeOfDay(hour: 0, minute: 0),
      );

      expect(toMidnight.eveningWindow, ('17:00:00', '24:00:00'));
      expect(toMidnight.afterMidnightWindow, isNull);
      expect(toMidnight.durationMinutes, 7 * 60);
    });

    test('folds back with the sentinel read as midnight', () {
      final loaded = OpeningHours.fromBands(
        eveningStart: '17:00:00',
        eveningEnd: '24:00:00',
        afterMidnightEnabled: false,
      );

      expect(loaded.closesAt, const TimeOfDay(hour: 0, minute: 0));
      expect(loaded.crossesMidnight, isTrue);
    });
  });

  group('the rule that protects night grouping', () {
    test('closing after 6am is refused, with a reason', () {
      const tooLate = OpeningHours(
        opensAt: evening,
        closesAt: TimeOfDay(hour: 8, minute: 0),
      );

      // A band from 00:00 to 08:00 is neither an evening nor an after-midnight
      // one, and the engine would have no answer for which night a booking in
      // it belongs to.
      expect(tooLate.isValid, isFalse);
      expect(tooLate.problem, contains('٦:٠٠ صباحًا'));
    });

    test('closing exactly at 6am is allowed', () {
      const limit = OpeningHours(
        opensAt: evening,
        closesAt: TimeOfDay(hour: 6, minute: 0),
      );

      expect(limit.isValid, isTrue);
      expect(limit.afterMidnightWindow, ('00:00:00', '06:00:00'));
    });

    test('identical open and close is refused', () {
      const same = OpeningHours(opensAt: evening, closesAt: evening);

      expect(same.isValid, isFalse);
      expect(same.problem, contains('متطابقان'));
    });
  });

  group('the existing venue keeps working untouched', () {
    test('17:00–24:00 plus 00:00–03:00 reads back as 5pm to 3am', () {
      // This is the real configuration of branch 12 today.
      final loaded = OpeningHours.fromBands(
        eveningStart: '17:00:00',
        eveningEnd: '24:00:00',
        afterMidnightEnd: '03:00:00',
        afterMidnightEnabled: true,
      );

      expect(arabicClock(loaded.opensAt), '5:00 م');
      expect(arabicClock(loaded.closesAt), '3:00 ص');

      // And saving it again sends back byte-identical windows.
      expect(loaded.eveningWindow, ('17:00:00', '24:00:00'));
      expect(loaded.afterMidnightWindow, ('00:00:00', '03:00:00'));
    });
  });

  group('times read as Arabic, never as machine text', () {
    test('the clock', () {
      expect(arabicClock(const TimeOfDay(hour: 17, minute: 0)), '5:00 م');
      expect(arabicClock(const TimeOfDay(hour: 3, minute: 0)), '3:00 ص');
      expect(arabicClock(const TimeOfDay(hour: 12, minute: 0)), '12:00 م');
      expect(arabicClock(const TimeOfDay(hour: 23, minute: 30)), '11:30 م');
      // Midnight is named rather than shown as a bare 12.
      expect(arabicClock(const TimeOfDay(hour: 0, minute: 0)), 'منتصف الليل');
    });

    test('never emits 24:00:00 or a seconds field', () {
      for (var h = 0; h < 24; h++) {
        final text = arabicClock(TimeOfDay(hour: h, minute: 0));
        expect(text, isNot(contains('24:')));
        expect(text, isNot(contains(':00:00')));
      }
    });

    test('the duration', () {
      expect(arabicDuration(10 * 60), '10 ساعات');
      expect(arabicDuration(60), 'ساعة');
      expect(arabicDuration(120), 'ساعتان');
      expect(arabicDuration(9 * 60 + 30), '9 ساعات و30 دقيقة');
      expect(arabicDuration(11 * 60), '11 ساعة');
    });
  });

  group('parsing what the server stores', () {
    test('the 24:00 sentinel is midnight, not an invalid hour', () {
      expect(OpeningHours.parseClock('24:00:00'),
          const TimeOfDay(hour: 0, minute: 0));
    });

    test('ordinary clocks', () {
      expect(OpeningHours.parseClock('17:00:00'),
          const TimeOfDay(hour: 17, minute: 0));
      expect(OpeningHours.parseClock('03:30'),
          const TimeOfDay(hour: 3, minute: 30));
    });

    test('nonsense yields null rather than a wrong time', () {
      expect(OpeningHours.parseClock(''), isNull);
      expect(OpeningHours.parseClock(null), isNull);
      expect(OpeningHours.parseClock('99:99'), isNull);
      expect(OpeningHours.parseClock('لا يوجد'), isNull);
    });
  });
}
