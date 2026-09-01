import 'package:flutter/material.dart';

/// When a pitch opens and when it closes — as its owner thinks of it.
///
/// The venue's night is stored as TWO records: an evening band and an
/// after-midnight band, because the booking engine decides which night a 1am
/// session belongs to by finding a band whose window lies wholly in the small
/// hours. That split is a correctness requirement, not a storage quirk.
///
/// It is also not something a pitch owner should ever have to think about.
/// They know one fact — "I open at five and close at three" — so that is the
/// only thing this screen asks for. The split happens here, on the way to the
/// server, and is folded back on the way in.
@immutable
class OpeningHours {
  const OpeningHours({required this.opensAt, required this.closesAt});

  final TimeOfDay opensAt;
  final TimeOfDay closesAt;

  /// The venue trades past midnight, so closing belongs to the next day.
  bool get crossesMidnight => _minutes(closesAt) <= _minutes(opensAt);

  /// How long the venue is open, in minutes. A night that runs to 3am is ten
  /// hours long, not a negative number.
  int get durationMinutes {
    final open = _minutes(opensAt);
    final close = _minutes(closesAt);

    return close > open ? close - open : (24 * 60 - open) + close;
  }

  /// The latest a venue may close and still have its night grouped correctly.
  ///
  /// `OperationalDay` recognises an after-midnight band by its window sitting
  /// wholly inside the small hours — `00:00 <= start < end <= 06:00`. A venue
  /// closing at 08:00 would produce a band that is neither evening nor
  /// after-midnight, and the engine would then have no answer to "which night
  /// does this booking belong to". So the rule is enforced where the manager
  /// can see it, rather than discovered later as mis-grouped bookings.
  static const latestCloseAfterMidnight = TimeOfDay(hour: 6, minute: 0);

  /// Why this cannot be saved, or null when it can.
  String? get problem {
    if (_minutes(opensAt) == _minutes(closesAt)) {
      return 'وقت الفتح والإغلاق متطابقان. اختر وقتين مختلفين.';
    }

    if (crossesMidnight &&
        _minutes(closesAt) > _minutes(latestCloseAfterMidnight)) {
      return 'أقصى وقت إغلاق بعد منتصف الليل هو ٦:٠٠ صباحًا.';
    }

    return null;
  }

  bool get isValid => problem == null;

  // ---- To the server -----------------------------------------------------

  /// The evening band's window. Always present: a venue is open in the
  /// evening or it is not open at all.
  ///
  /// Ends at `24:00:00` rather than `23:00` when the night continues, so the
  /// last hour before midnight belongs to the evening instead of falling into
  /// a gap between the two bands.
  (String, String) get eveningWindow => (
        _wire(opensAt),
        crossesMidnight ? '24:00:00' : _wire(closesAt),
      );

  /// The after-midnight band's window, or null when the venue shuts by
  /// midnight — in which case that band is simply switched off.
  (String, String)? get afterMidnightWindow {
    if (!crossesMidnight) return null;
    if (_minutes(closesAt) == 0) return null; // closes exactly at midnight

    return ('00:00:00', _wire(closesAt));
  }

  bool get needsAfterMidnight => afterMidnightWindow != null;

  // ---- From the server ---------------------------------------------------

  /// Folds the two stored bands back into the one thing the manager entered.
  ///
  /// The evening band supplies the opening time. Closing comes from the
  /// after-midnight band when the venue runs that late, and from the evening
  /// band otherwise — where `24:00:00` means midnight.
  factory OpeningHours.fromBands({
    String? eveningStart,
    String? eveningEnd,
    String? afterMidnightEnd,
    bool afterMidnightEnabled = false,
  }) {
    final opens = parseClock(eveningStart) ?? const TimeOfDay(hour: 17, minute: 0);

    if (afterMidnightEnabled) {
      final closes = parseClock(afterMidnightEnd);
      if (closes != null) return OpeningHours(opensAt: opens, closesAt: closes);
    }

    return OpeningHours(
      opensAt: opens,
      closesAt: parseClock(eveningEnd) ?? const TimeOfDay(hour: 0, minute: 0),
    );
  }

  /// `24:00:00` is the schedule engine's "end of day" sentinel and reads as
  /// midnight, never as an invalid 24th hour.
  static TimeOfDay? parseClock(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (minute > 59) return null;
    if (hour == 24) return const TimeOfDay(hour: 0, minute: 0);
    if (hour > 23) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _wire(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  @override
  bool operator ==(Object other) =>
      other is OpeningHours &&
      _minutes(other.opensAt) == _minutes(opensAt) &&
      _minutes(other.closesAt) == _minutes(closesAt);

  @override
  int get hashCode => Object.hash(_minutes(opensAt), _minutes(closesAt));
}

/// A clock time as a venue manager reads it: «٥:٠٠ م», never «17:00:00».
String arabicClock(TimeOfDay t) {
  if (t.hour == 0 && t.minute == 0) return 'منتصف الليل';

  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'ص' : 'م';

  return '$hour12:$minute $period';
}

/// "١٠ ساعات" / "٩ ساعات و٣٠ دقيقة"
String arabicDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  final hourPart = switch (hours) {
    0 => '',
    1 => 'ساعة',
    2 => 'ساعتان',
    _ when hours <= 10 => '$hours ساعات',
    _ => '$hours ساعة',
  };

  if (rest == 0) return hourPart;
  if (hourPart.isEmpty) return '$rest دقيقة';

  return '$hourPart و$rest دقيقة';
}
