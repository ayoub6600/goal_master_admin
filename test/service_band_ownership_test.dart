import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_setup/domain/opening_hours.dart';

/// One fact, one owner.
///
/// «الملاعب والخدمات» owns a pitch's name and price. «فترات الحجز» owns when
/// the venue is open and which pitches can be booked. The service editor used
/// to ask the band question too — in the vocabulary the hours screen no longer
/// uses — so the same fact had two owners that could disagree.
///
/// Removing the question means the flags must be DERIVED, and there are two
/// ways to derive them wrongly:
///
///   * sending "both bands" for every pitch widens a pitch that was only ever
///     available in the evening, because the server deactivates whatever is
///     missing from a band's list and activates whatever is in it;
///   * sending "after midnight" for a new pitch while that band is switched
///     off re-creates the band as enabled, quietly reopening hours the venue
///     had closed.
///
/// These pin the rule that avoids both.
void main() {
  /// The rule the service editor applies when it saves.
  ({bool evening, bool afterMidnight}) flagsFor({
    required bool isNew,
    bool hadEvening = false,
    bool hadAfterMidnight = false,
    required bool afterMidnightBandEnabled,
  }) {
    return (
      evening: isNew ? true : hadEvening,
      afterMidnight: isNew ? afterMidnightBandEnabled : hadAfterMidnight,
    );
  }

  group('an existing pitch keeps the bands it already had', () {
    test('evening-only stays evening-only', () {
      final flags = flagsFor(
        isNew: false,
        hadEvening: true,
        hadAfterMidnight: false,
        afterMidnightBandEnabled: true,
      );

      expect(flags.evening, isTrue);
      expect(
        flags.afterMidnight,
        isFalse,
        reason: 'saving a price widened an evening-only pitch',
      );
    });

    test('an all-night pitch stays all-night', () {
      final flags = flagsFor(
        isNew: false,
        hadEvening: true,
        hadAfterMidnight: true,
        afterMidnightBandEnabled: true,
      );

      expect(flags.evening, isTrue);
      expect(flags.afterMidnight, isTrue);
    });

    test('an after-midnight-only pitch is not pulled into the evening', () {
      final flags = flagsFor(
        isNew: false,
        hadEvening: false,
        hadAfterMidnight: true,
        afterMidnightBandEnabled: true,
      );

      expect(flags.evening, isFalse);
      expect(flags.afterMidnight, isTrue);
    });

    test('editing the price changes no band at all', () {
      // The price lives on the service row; the bands live on the links. The
      // editor sends the bands back exactly as it read them.
      const before = (evening: true, afterMidnight: false);
      final after = flagsFor(
        isNew: false,
        hadEvening: before.evening,
        hadAfterMidnight: before.afterMidnight,
        afterMidnightBandEnabled: true,
      );

      expect(after.evening, before.evening);
      expect(after.afterMidnight, before.afterMidnight);
    });
  });

  group('a new pitch takes the venue\'s current hours', () {
    test('a venue open past midnight gets both bands', () {
      final flags = flagsFor(isNew: true, afterMidnightBandEnabled: true);

      expect(flags.evening, isTrue);
      expect(flags.afterMidnight, isTrue);
    });

    test('a venue that shuts by midnight gets the evening only', () {
      // Sending the after-midnight band here would re-create it as enabled,
      // reopening hours the venue had closed.
      final flags = flagsFor(isNew: true, afterMidnightBandEnabled: false);

      expect(flags.evening, isTrue);
      expect(
        flags.afterMidnight,
        isFalse,
        reason: 'a new pitch switched a disabled after-midnight band back on',
      );
    });

    test('the default follows the hours, never a hardcoded assumption', () {
      // Same pitch, two venues: the answer comes from the venue's own bands.
      expect(flagsFor(isNew: true, afterMidnightBandEnabled: true).afterMidnight,
          isTrue);
      expect(flagsFor(isNew: true, afterMidnightBandEnabled: false).afterMidnight,
          isFalse);
    });
  });

  group('the two screens agree on what the hours are', () {
    test('a night to 3am means the after-midnight band is on', () {
      const night = OpeningHours(
        opensAt: TimeOfDay(hour: 17, minute: 0),
        closesAt: TimeOfDay(hour: 3, minute: 0),
      );

      expect(night.needsAfterMidnight, isTrue);
      // So a pitch added afterwards is bookable in the small hours.
      expect(
        flagsFor(isNew: true, afterMidnightBandEnabled: night.needsAfterMidnight)
            .afterMidnight,
        isTrue,
      );
    });

    test('a night to 11pm means it is off', () {
      const early = OpeningHours(
        opensAt: TimeOfDay(hour: 17, minute: 0),
        closesAt: TimeOfDay(hour: 23, minute: 0),
      );

      expect(early.needsAfterMidnight, isFalse);
      expect(
        flagsFor(isNew: true, afterMidnightBandEnabled: early.needsAfterMidnight)
            .afterMidnight,
        isFalse,
      );
    });
  });
}
