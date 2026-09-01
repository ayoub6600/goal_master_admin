import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';

/// One recurring booking, assembled from the sessions the list returns.
///
/// The API models a monthly booking as N separate `booking_info` rows, one per
/// session, all pointing at the same `booking_series`. Rendered row by row,
/// a four-week booking appeared as four identical cards — same customer, same
/// pitch, same slot, four "cancel" buttons — and the manager had no way to see
/// that they were one commitment.
///
/// Grouping is done on the server's `booking_series_id` and nothing else.
/// Sessions that share a customer and a clock time are NOT assumed to be the
/// same booking; a legacy row with no series id stays a group of one, which is
/// exactly what it is.
class MonthlySeriesGroup {
  MonthlySeriesGroup({
    required this.seriesId,
    required this.occurrences,
  });

  /// 0 for a legacy session that predates the series model.
  final int seriesId;

  /// Every session, ordered by the date it is played on.
  final List<MonthlyBookingResponse> occurrences;

  MonthlyBookingResponse get _first => occurrences.first;

  String get customerName => _first.customer.fullName;
  String get customerPhone => _first.customer.phoneNo;
  String get branchName => _first.branchName;

  /// The reference a manager can quote. For a real series that is the series
  /// number; a legacy standalone session falls back to its own.
  int get reference => seriesId > 0 ? seriesId : _first.id;

  bool get isSeries => seriesId > 0 && occurrences.length > 1;

  /// The venue can still act on this booking.
  bool get isActive => occurrences.any((o) => o.isMonthlyActive && !o.isCancelled);

  int get totalCount => occurrences.length;
  int get playedCount => occurrences.where((o) => o.isDone).length;
  int get cancelledCount => occurrences.where((o) => o.isCancelled).length;
  bool get hasReplacement => occurrences.any((o) => o.isReplacement);

  // ---- Money ------------------------------------------------------------
  //
  // Summed from the session rows, which are the same numbers the server's own
  // payment authority works from. Nothing here decides what is owed; it only
  // adds up what the server already recorded. Cancelled sessions are excluded
  // from what is due, because they are not going to be played.

  Iterable<MonthlyBookingResponse> get _billable =>
      occurrences.where((o) => !o.isCancelled);

  double get totalAmount =>
      _billable.fold(0, (sum, o) => sum + _amountOf(o));

  double get paidAmount => _billable.fold(
      0, (sum, o) => sum + (o.occurrencePaidAmount > 0 ? o.occurrencePaidAmount : o.paidAmount));

  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  /// The session row's own price where the server sent one, else the envelope.
  static double _amountOf(MonthlyBookingResponse o) =>
      o.serviceAmount > 0 ? o.serviceAmount : o.totalAmount;

  SeriesPaymentState get paymentState {
    if (paidAmount <= 0) return SeriesPaymentState.unpaid;
    if (remainingAmount <= 0.009) return SeriesPaymentState.settled;
    return SeriesPaymentState.partial;
  }

  // ---- The next session -------------------------------------------------

  /// The next session that will actually be played, or null when none remain.
  ///
  /// Deterministic by construction: sessions are sorted by their own date, and
  /// the first one that is neither in the past nor cancelled wins. It is never
  /// "whichever row the join returned first", and an old session is never
  /// relabelled as upcoming — a finished series reports null and the card says
  /// so instead.
  MonthlyBookingResponse? nextOccurrence(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    for (final o in occurrences) {
      if (o.isCancelled) continue;
      final date = occurrenceDate(o);
      if (date == null) continue;
      if (!date.isBefore(today)) return o;
    }

    return null;
  }

  /// Position of the next session, 1-based, for "الموعد 3 من 4".
  int? nextPosition(DateTime now) {
    final next = nextOccurrence(now);
    if (next == null) return null;

    return occurrences.indexOf(next) + 1;
  }

  /// The last session played, shown when nothing is upcoming.
  MonthlyBookingResponse? get lastOccurrence {
    for (final o in occurrences.reversed) {
      if (!o.isCancelled) return o;
    }
    return null;
  }

  /// When a session actually starts — date and clock together.
  ///
  /// `start_at` first: it is the occurrence model's own column and the value
  /// the booking engine schedules against, so reading it means the screen and
  /// the engine can never disagree. The fallbacks exist for rows written
  /// before that column: `date` carries the day but no time, and `start_time`
  /// is a DATETIME whose date half is the series creation day — correct clock,
  /// meaningless date. Neither is used while `start_at` is present.
  static DateTime? occurrenceStart(MonthlyBookingResponse o) {
    final authoritative = parseLocalDateTime(o.startAt);
    if (authoritative != null) return authoritative;

    final day = occurrenceDate(o);
    if (day == null) return null;

    final clock = clockOf(o.startTime);
    if (clock == null) return day;

    return DateTime(day.year, day.month, day.day, clock.$1, clock.$2);
  }

  static DateTime? occurrenceEnd(MonthlyBookingResponse o) {
    final authoritative = parseLocalDateTime(o.endAt);
    if (authoritative != null) return authoritative;

    final start = occurrenceStart(o);
    final clock = clockOf(o.endTime);
    if (start == null || clock == null) return null;

    var end = DateTime(start.year, start.month, start.day, clock.$1, clock.$2);
    // A night that runs past midnight ends on the following day.
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));

    return end;
  }

  /// The calendar day a session is played on.
  static DateTime? occurrenceDate(MonthlyBookingResponse o) {
    final authoritative = parseLocalDateTime(o.startAt);
    if (authoritative != null) {
      return DateTime(
        authoritative.year,
        authoritative.month,
        authoritative.day,
      );
    }

    return parseLocalDateTime(
      o.occurrenceDate.isNotEmpty ? o.occurrenceDate : o.date,
    );
  }

  /// The time of day out of «20:00:00» or «2026-08-30 20:00:00».
  static (int, int)? clockOf(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final full = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (full != null) return (full.hour, full.minute);

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;

    return (hour, minute);
  }

  // ---- Building ---------------------------------------------------------

  /// Groups a flat list of sessions into one entry per recurring booking,
  /// newest booking first, sessions inside each ordered by date.
  static List<MonthlySeriesGroup> from(List<MonthlyBookingResponse> rows) {
    final grouped = <int, List<MonthlyBookingResponse>>{};
    final standalone = <MonthlySeriesGroup>[];

    for (final row in rows) {
      if (row.belongsToSeries) {
        grouped.putIfAbsent(row.seriesId, () => []).add(row);
      } else {
        standalone.add(MonthlySeriesGroup(seriesId: 0, occurrences: [row]));
      }
    }

    final groups = grouped.entries.map((e) {
      final items = [...e.value]..sort(_byDate);
      return MonthlySeriesGroup(seriesId: e.key, occurrences: items);
    }).toList();

    groups.addAll(standalone);
    // Most recently created booking first, matching the list's own order.
    groups.sort((a, b) => b.reference.compareTo(a.reference));

    return groups;
  }

  static int _byDate(MonthlyBookingResponse a, MonthlyBookingResponse b) {
    final da = occurrenceDate(a);
    final db = occurrenceDate(b);
    if (da == null || db == null) return a.sequence.compareTo(b.sequence);

    final byDate = da.compareTo(db);
    return byDate != 0 ? byDate : a.sequence.compareTo(b.sequence);
  }
}

/// What the manager is owed, in words rather than an enum number.
enum SeriesPaymentState {
  unpaid,
  partial,
  settled;

  String get label => switch (this) {
        SeriesPaymentState.unpaid => 'غير مدفوع',
        SeriesPaymentState.partial => 'مدفوع جزئيًا',
        SeriesPaymentState.settled => 'خالص',
      };
}
