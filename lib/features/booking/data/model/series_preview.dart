/// The four appointments a recurring booking would create, before it is made.
///
/// The manager used to get a bare switch and a generic refusal after pressing
/// confirm. This is the same contract the customer app reads — one preview
/// call describing every week, which weeks are taken, and what each taken week
/// could move to — so there is one recurrence engine and one set of rules, not
/// a manager-only copy of them.
///
/// Every row carries its own `startAt`/`endAt`, band and price. Nothing here
/// recombines a date with a clock, and nothing multiplies one week's price by
/// four.
class SeriesPreview {
  const SeriesPreview({
    required this.dates,
    required this.allAvailable,
    required this.satisfiable,
    required this.planSignature,
    required this.targetOccurrenceCount,
    this.pricePerOccurrence = 0,
    this.totalAmount = 0,
    this.resolvedTotalAmount = 0,
    this.finalOccurrenceCount = 0,
    this.replacementEnabled = false,
    this.summary = '',
    this.dayName = '',
  });

  final List<PreviewDate> dates;
  final bool allAvailable;

  /// Whether ANY plan reaches the target. False means the manager must pick a
  /// different time or start date.
  final bool satisfiable;

  /// The fingerprint of this exact plan, sent back on confirm so the booking
  /// can only be made on the appointments that were actually shown.
  final String planSignature;

  final int targetOccurrenceCount;
  final double pricePerOccurrence;
  final double totalAmount;

  /// Summed from the rows that will actually be booked, so a replacement in a
  /// differently priced band is reflected instead of assumed away.
  final double resolvedTotalAmount;

  final int finalOccurrenceCount;
  final bool replacementEnabled;
  final String summary;
  final String dayName;

  /// The four weekly positions this booking is for.
  ///
  /// Every requested week appears exactly once, whether it is free, taken, or
  /// has been moved. An extension week — one the server reached further out
  /// for after dropping a taken one — is not a position the manager asked
  /// for, so it is not shown as one.
  List<PreviewDate> get positions =>
      dates.where((d) => !d.isExtension).toList();

  /// The appointments that will exist if this is confirmed now — a moved week
  /// appears once, at its new time. Never one row per position plus an extra
  /// for the replacement.
  List<PreviewDate> get plannedOccurrences =>
      positions.where((d) => d.available || d.isReplaced).toList();

  /// Positions still needing the manager's attention.
  List<PreviewDate> get unresolved =>
      positions.where((d) => !d.available && !d.isReplaced).toList();

  bool get hasUnresolved => unresolved.isNotEmpty;

  /// Ready to book: every position filled, nothing left to fix.
  ///
  /// Readiness is judged from the positions and the server's own count of what
  /// it would create — not from `satisfiable`, which asks a different
  /// question. A plan holding four agreed weeks with one still taken is
  /// formally unsatisfiable and yet entirely resolvable, which is exactly the
  /// state the manager is in before choosing a replacement.
  bool get isReadyToConfirm =>
      !hasUnresolved &&
      positions.length >= targetOccurrenceCount &&
      finalOccurrenceCount >= targetOccurrenceCount;

  /// No arrangement of these weeks works at all — a different day or hour is
  /// needed. Distinct from "one week is taken", which is fixable in place.
  bool get isImpossible => !satisfiable && positions.isEmpty;

  /// The total as the plan now stands, including any replacements the manager
  /// has chosen but not yet sent back to the server.
  double get displayTotal {
    if (dates.any((d) => d.isReplaced)) {
      return plannedOccurrences.fold<double>(
        0,
        (sum, d) => sum + (d.chosenReplacement?.price ?? d.price),
      );
    }

    return resolvedTotalAmount > 0 ? resolvedTotalAmount : totalAmount;
  }

  SeriesPreview copyWith({List<PreviewDate>? dates}) {
    return SeriesPreview(
      dates: dates ?? this.dates,
      allAvailable: allAvailable,
      satisfiable: satisfiable,
      planSignature: planSignature,
      targetOccurrenceCount: targetOccurrenceCount,
      pricePerOccurrence: pricePerOccurrence,
      totalAmount: totalAmount,
      resolvedTotalAmount: resolvedTotalAmount,
      finalOccurrenceCount: finalOccurrenceCount,
      replacementEnabled: replacementEnabled,
      summary: summary,
      dayName: dayName,
    );
  }

  factory SeriesPreview.fromJson(Map<String, dynamic> json) {
    return SeriesPreview(
      dates: ((json['dates'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => PreviewDate.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      allAvailable: json['all_available'] == true,
      // Absent on an older backend: treat the request as workable and let the
      // server refuse it, rather than blocking the button locally.
      satisfiable: json['satisfiable'] != false,
      planSignature: _string(json['plan_signature']),
      targetOccurrenceCount: json['target_occurrence_count'] == null
          ? 4
          : _int(json['target_occurrence_count']),
      pricePerOccurrence: _double(json['price_per_occurrence']),
      totalAmount: _double(json['total_amount']),
      resolvedTotalAmount: _double(json['resolved_total_amount']),
      finalOccurrenceCount: _int(json['final_occurrence_count']),
      replacementEnabled: json['replacement_enabled'] == true,
      summary: _string(json['summary']),
      dayName: _string(json['day_name']),
    );
  }
}

/// One position in the series.
class PreviewDate {
  const PreviewDate({
    required this.sequence,
    required this.date,
    required this.available,
    required this.action,
    this.message = '',
    this.startTime = '',
    this.endTime = '',
    this.startAt,
    this.endAt,
    this.employeeId = 0,
    this.price = 0,
    this.canReplace = false,
    this.replacementOptions,
    this.chosenReplacement,
    this.isReplacement = false,
    this.originalDate = '',
    this.isExtension = false,
  });

  /// 1..4 for a week that becomes a booking; 0 for one that is skipped.
  final int sequence;
  final String date;
  final bool available;

  /// "book" | "skip" | "block" — what the backend plans to do with this week.
  final String action;
  final String message;

  /// This row's OWN times. One appointment may sit at a different hour from
  /// the rest once it has been moved, so nothing may assume the series time
  /// applies to every line.
  final String startTime;
  final String endTime;

  /// The authoritative moment, from the server. Never rebuilt from
  /// [date] plus a clock.
  final DateTime? startAt;
  final DateTime? endAt;

  /// The band this appointment falls in, which is what prices it.
  final int employeeId;
  final double price;

  final bool canReplace;
  final ReplacementOptions? replacementOptions;

  /// Chosen by the manager but not yet sent back. The server re-validates it
  /// under lock before anything is booked.
  final ReplacementSlot? chosenReplacement;

  /// The backend has already applied a replacement here: the date and times
  /// above are the real ones.
  final bool isReplacement;
  final String originalDate;
  final bool isExtension;

  bool get isReplaced => chosenReplacement != null || isReplacement;
  bool get isBlocked => action == 'block';

  /// What this position will actually be, once any local choice is applied.
  DateTime? get effectiveStartAt => chosenReplacement?.startAt ?? startAt;
  DateTime? get effectiveEndAt => chosenReplacement?.endAt ?? endAt;

  PreviewDate copyWith({
    ReplacementSlot? chosenReplacement,
    bool clearChoice = false,
  }) {
    return PreviewDate(
      sequence: sequence,
      date: date,
      available: available,
      action: action,
      message: message,
      startTime: startTime,
      endTime: endTime,
      startAt: startAt,
      endAt: endAt,
      employeeId: employeeId,
      price: price,
      canReplace: canReplace,
      replacementOptions: replacementOptions,
      chosenReplacement:
          clearChoice ? null : (chosenReplacement ?? this.chosenReplacement),
      isReplacement: isReplacement,
      originalDate: originalDate,
      isExtension: isExtension,
    );
  }

  /// The shape the booking and preview endpoints expect a chosen replacement
  /// in. `original_date` is what makes it a MOVE of this position rather than
  /// an additional appointment.
  Map<String, dynamic>? toReplacementJson() {
    final choice = chosenReplacement;
    if (choice == null) return null;

    return {
      'original_date': date,
      'date': choice.date,
      'start_time': choice.startTime,
      'end_time': choice.endTime,
    };
  }

  factory PreviewDate.fromJson(Map<String, dynamic> json) {
    return PreviewDate(
      sequence: _int(json['sequence']),
      date: _string(json['date']),
      available: json['available'] == true,
      action: _string(json['action']).isEmpty
          ? (json['available'] == true ? 'book' : 'block')
          : _string(json['action']),
      message: _string(json['message']),
      startTime: _string(json['start_time']),
      endTime: _string(json['end_time']),
      startAt: _dateTime(json['start_at']),
      endAt: _dateTime(json['end_at']),
      employeeId: _int(json['employee_id']),
      price: _double(json['price']),
      canReplace: json['can_replace'] == true,
      replacementOptions: json['replacement_options'] == null
          ? null
          : ReplacementOptions.fromJson(
              Map<String, dynamic>.from(json['replacement_options'] as Map)),
      isReplacement: json['is_replacement'] == true,
      originalDate: _string(json['original_date']),
      isExtension: json['is_extension'] == true,
    );
  }
}

/// What a taken week could move to, already ranked by the server.
class ReplacementOptions {
  const ReplacementOptions({
    this.sameDay = const [],
    this.nearbyDays = const [],
    this.windowDays = 0,
    this.enabled = false,
  });

  /// The same evening, shifted. Usually what a venue wants first.
  final List<ReplacementSlot> sameDay;

  /// A day either side, per the venue's existing replacement window.
  final List<ReplacementSlot> nearbyDays;

  final int windowDays;
  final bool enabled;

  bool get hasAny => sameDay.isNotEmpty || nearbyDays.isNotEmpty;

  factory ReplacementOptions.fromJson(Map<String, dynamic> json) {
    List<ReplacementSlot> parse(dynamic list) => ((list as List?) ?? const [])
        .whereType<Map>()
        .map((e) => ReplacementSlot.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ReplacementOptions(
      sameDay: parse(json['same_day']),
      nearbyDays: parse(json['nearby_days']),
      windowDays: _int(json['window_days']),
      enabled: json['enabled'] == true,
    );
  }
}

/// One suggestion. Availability is the server's word and is checked again
/// under lock on confirm — this only decides what the sheet offers.
class ReplacementSlot {
  const ReplacementSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.startAt,
    this.endAt,
    this.employeeId = 0,
    this.price = 0,
    this.dateLabel = '',
    this.timeLabel = '',
    this.sameDay = false,
    this.dayDistance = 0,
  });

  final String date;
  final String startTime;
  final String endTime;
  final DateTime? startAt;
  final DateTime? endAt;
  final int employeeId;
  final double price;
  final String dateLabel;
  final String timeLabel;
  final bool sameDay;
  final int dayDistance;

  factory ReplacementSlot.fromJson(Map<String, dynamic> json) {
    return ReplacementSlot(
      date: _string(json['date']),
      startTime: _string(json['start_time']),
      endTime: _string(json['end_time']),
      startAt: _dateTime(json['start_at']),
      endAt: _dateTime(json['end_at']),
      employeeId: _int(json['employee_id']),
      price: _double(json['price']),
      dateLabel: _string(json['date_label']),
      timeLabel: _string(json['time_label']),
      sameDay: json['same_day'] == true,
      dayDistance: _int(json['day_distance']),
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _string(dynamic value) => value?.toString() ?? '';

DateTime? _dateTime(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  // A trailing Z would be read as UTC and shift the day; stored values are
  // already the venue's local wall clock.
  return DateTime.tryParse(text.endsWith('Z')
      ? text.substring(0, text.length - 1)
      : text);
}
