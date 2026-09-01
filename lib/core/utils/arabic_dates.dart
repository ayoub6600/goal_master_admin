/// Dates and times as a manager reads them, not as the API stores them.
///
/// The API sends full ISO timestamps (`2026-08-29T21:00:00.000000Z`). Putting
/// those on a card is unreadable and, worse, the trailing `Z` invites reading
/// a local 21:00 as UTC. Everything here formats the calendar values only.
const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// `DateTime.weekday` is 1..7 starting on Monday.
const _arabicWeekdays = [
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// Parsed without timezone conversion.
///
/// `DateTime.parse` on a `...Z` string returns UTC, and rendering that shifts
/// the day — a 21:00 booking on the 29th would show as the 30th. The stored
/// value is already the venue's local time, so it is read literally.
DateTime? parseLocalDateTime(String? value) {
  if (value == null || value.isEmpty) return null;

  final cleaned = value.endsWith('Z')
      ? value.substring(0, value.length - 1)
      : value;

  return DateTime.tryParse(cleaned);
}

/// "الثلاثاء 29 أغسطس"
String arabicDayAndDate(String? value) {
  final d = parseLocalDateTime(value);
  if (d == null) return value ?? '';

  return '${_arabicWeekdays[d.weekday - 1]} ${d.day} ${_arabicMonths[d.month - 1]}';
}

/// "29 أغسطس"
String arabicShortDate(String? value) {
  final d = parseLocalDateTime(value);
  if (d == null) return value ?? '';

  return '${d.day} ${_arabicMonths[d.month - 1]}';
}

/// "29 أغسطس 2026"
String arabicDateWithYear(String? value) {
  final d = parseLocalDateTime(value);
  if (d == null) return value ?? '';

  return '${d.day} ${_arabicMonths[d.month - 1]} ${d.year}';
}

/// "6:00 مساءً" — a 24-hour clock reads as a timestamp, not an appointment.
///
/// Accepts both a full datetime and a bare "HH:mm" / "HH:mm:ss", because the
/// API sends times on their own for a session's clock time.
String arabicTime(String? value) {
  if (value == null || value.isEmpty) return '';

  int? hour;
  int? minute;

  final bare = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
  final looksLikeTimeOnly = !value.contains('-') && bare != null;

  if (looksLikeTimeOnly) {
    hour = int.tryParse(bare.group(1)!);
    minute = int.tryParse(bare.group(2)!);
  } else {
    final d = parseLocalDateTime(value);
    hour = d?.hour;
    minute = d?.minute;
  }

  if (hour == null || minute == null) return value;

  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'صباحًا' : 'مساءً';

  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

/// "الأحد" — the weekday on its own, for "every [day]".
String arabicWeekday(String? value) {
  final d = parseLocalDateTime(value);
  if (d == null) return '';

  return _arabicWeekdays[d.weekday - 1];
}

// ---------------------------------------------------------------------------
// Occurrence-aware helpers.
//
// Added for the booking flow, which works in real timestamps rather than the
// clock strings the rest of this file was written for. Additive on purpose:
// existing call sites keep the wording they already ship with.
// ---------------------------------------------------------------------------

/// The part of the day a clock time belongs to.
///
/// Midnight gets its own name. «12:00 صباحًا» is technically right and reads
/// wrong on a booking that a manager thinks of as "the end of Saturday night".
String arabicDayPeriodOf(int hour, int minute) {
  if (hour == 0 && minute == 0) return 'منتصف الليل';
  if (hour < 6) return 'ليلاً';
  if (hour < 12) return 'صباحًا';
  if (hour == 12 && minute == 0) return 'ظهرًا';
  return 'مساءً';
}

String _clock12(DateTime t) {
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$hour12:${t.minute.toString().padLeft(2, '0')}';
}

/// A single slot's start, short enough for a grid cell: "12:00 ص".
String arabicSlotClock(DateTime t) {
  final suffix = t.hour < 12 ? 'ص' : 'م';
  return '${_clock12(t)} $suffix';
}

/// A slot as one phrase: "5:00 – 6:00 مساءً".
///
/// The period is written once when both ends share it, which is the normal
/// case. When the slot crosses a boundary — 11:00 مساءً – 12:00 منتصف الليل —
/// both are named, because that is exactly what needs noticing.
String arabicRange(DateTime from, DateTime to) {
  final fromPeriod = arabicDayPeriodOf(from.hour, from.minute);
  final toPeriod = arabicDayPeriodOf(to.hour, to.minute);

  if (fromPeriod == toPeriod) {
    return '${_clock12(from)} – ${_clock12(to)} $fromPeriod';
  }

  return '${_clock12(from)} $fromPeriod – ${_clock12(to)} $toPeriod';
}

/// "الأحد 30 أغسطس", from a real DateTime rather than a string.
String arabicDayAndDateOf(DateTime d) =>
    '${_arabicWeekdays[d.weekday - 1]} ${d.day} ${_arabicMonths[d.month - 1]}';

/// "السبت" — the weekday alone.
String arabicWeekdayOf(DateTime d) => _arabicWeekdays[d.weekday - 1];

/// "30 أغسطس"
String arabicShortDateOf(DateTime d) => '${d.day} ${_arabicMonths[d.month - 1]}';
