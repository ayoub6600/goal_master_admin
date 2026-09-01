import 'package:intl/intl.dart';

/// The authoritative datetimes of a single booking occurrence.
///
/// A venue's night is not a calendar day. The night of Saturday 29 August runs
/// past midnight into Sunday 30 August, so the 00:00 slot a manager taps while
/// browsing Saturday's night is booked on Sunday. The server decides which
/// calendar day each slot falls on and returns it as `start_at` / `end_at`.
///
/// Those two datetimes are the only source of truth for what is booked.
/// `focusedDay` — the operational night — chooses which night to list and
/// groups the result. It must never become the occurrence's calendar date: for
/// an after-midnight slot the two differ by a day, and submitting the night
/// books the venue 24 hours early and anchors a monthly series on the wrong
/// weekday for twelve weeks.
///
/// Ported from the customer app, which reached this shape first. Deliberately
/// a copy rather than a shared package: the two apps ship independently, and a
/// shared dependency would couple their release cycles to save sixty lines.
class BookingOccurrence {
  const BookingOccurrence({
    required this.startAt,
    required this.endAt,
    required this.employeeId,
    this.price,
  });

  final DateTime startAt;
  final DateTime endAt;

  /// The internal time band. Invisible to the manager, but it decides the
  /// price — fees are keyed on (employee, service) — so the band belonging to
  /// THIS slot has to travel with it. Substituting the evening band for an
  /// after-midnight slot would quietly charge the wrong rate.
  final int employeeId;

  /// The fee the server quoted for this exact slot, when it supplied one.
  /// Never recomputed on the device.
  final double? price;

  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _time = DateFormat('HH:mm:ss');
  static final DateFormat _wire = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Returns null when no slot has been selected, so callers fail loudly
  /// rather than falling back to the night.
  static BookingOccurrence? tryFrom(
    dynamic start,
    dynamic end, {
    int? employeeId,
    double? price,
  }) {
    final parsedStart = _parse(start);
    final parsedEnd = _parse(end);
    if (parsedStart == null || parsedEnd == null || employeeId == null) {
      return null;
    }
    return BookingOccurrence(
      startAt: parsedStart,
      endAt: parsedEnd,
      employeeId: employeeId,
      price: price,
    );
  }

  static DateTime? _parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// The calendar date the booking is played on — taken from the START.
  /// A 23:00 → 00:00 booking belongs to the night it starts, not the minute
  /// it ends.
  String get serviceDate => _date.format(startAt);

  String get startTime => _time.format(startAt);

  String get endTime => _time.format(endAt);

  /// Sent alongside the legacy fields so the server can prove the client's
  /// date and its own agree, instead of trusting a bare `service_date`.
  String get startAtWire => _wire.format(startAt);

  String get endAtWire => _wire.format(endAt);

  /// Whatever the server said, in minutes. Never assumed to be sixty: this
  /// flow used to discard the server's end and substitute start + 1 hour.
  int get durationMinutes => endAt.difference(startAt).inMinutes;

  bool get crossesMidnight =>
      startAt.year != endAt.year ||
      startAt.month != endAt.month ||
      startAt.day != endAt.day;

  @override
  String toString() =>
      'BookingOccurrence($startAtWire → $endAtWire, band $employeeId)';
}
