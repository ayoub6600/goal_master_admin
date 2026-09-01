/// One bookable slot of an operational night, exactly as the server described
/// it.
///
/// Replaces `TimeslotModel`, which carried only three clock fields and so
/// could not say which calendar day a slot fell on. The manager app had to
/// rebuild a DateTime from the browsed night plus the clock string, which put
/// every after-midnight slot a day early, and it substituted a fixed one-hour
/// duration for the end the server had sent.
///
/// Nothing here is derived on the device. Every field is the server's answer.
class OperationalSlot {
  const OperationalSlot({
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.startAt,
    required this.endAt,
    required this.isAvailable,
    required this.crossesMidnight,
    this.price,
  });

  /// The internal band. Hidden from the manager, but it keys the price.
  final int employeeId;

  /// The slot's own calendar date — the night's date for an evening slot, the
  /// following day for an after-midnight one.
  final String date;

  final String startTime;
  final String endTime;

  /// The authority.
  final DateTime startAt;
  final DateTime endAt;

  final bool isAvailable;

  /// True when this single slot runs across midnight (a 23:00 → 00:00), which
  /// is not the same thing as being an after-midnight slot.
  final bool crossesMidnight;

  final double? price;

  /// Whether this slot belongs to the part of the night past midnight, judged
  /// by comparing its own date to the night's — never by looking at the clock
  /// and guessing.
  bool isAfterMidnightOf(String operationalDate) => date != operationalDate;

  static OperationalSlot? fromJson(Map<String, dynamic> json) {
    final startAt = DateTime.tryParse((json['start_at'] ?? '').toString());
    final endAt = DateTime.tryParse((json['end_at'] ?? '').toString());

    // A slot without authoritative datetimes cannot be booked safely, so it is
    // dropped rather than guessed at.
    if (startAt == null || endAt == null) return null;

    return OperationalSlot(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      startAt: startAt,
      endAt: endAt,
      isAvailable: (json['is_available'] as num?)?.toInt() == 1,
      crossesMidnight: json['crosses_midnight'] == true,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

/// One night's answer: the night that was asked for, and everything in it.
class OperationalNight {
  const OperationalNight({
    required this.operationalDate,
    required this.slots,
  });

  final String operationalDate;
  final List<OperationalSlot> slots;

  factory OperationalNight.fromJson(Map<String, dynamic> json) {
    final raw = (json['slots'] as List?) ?? const [];

    return OperationalNight(
      operationalDate: (json['operational_date'] ?? '').toString(),
      slots: raw
          .whereType<Map<String, dynamic>>()
          .map(OperationalSlot.fromJson)
          .whereType<OperationalSlot>()
          .toList(),
    );
  }

  List<OperationalSlot> get evening =>
      slots.where((s) => !s.isAfterMidnightOf(operationalDate)).toList();

  List<OperationalSlot> get afterMidnight =>
      slots.where((s) => s.isAfterMidnightOf(operationalDate)).toList();

  bool get hasAfterMidnight => afterMidnight.isNotEmpty;
}

/// Whether the night already in progress still has slots worth offering.
///
/// The server decides this. The app never works out "yesterday" from the
/// device clock — a manager at 00:30 is inside Saturday's night, and only the
/// server knows which night that is and whether anything is left in it.
class PreviousNightContext {
  const PreviousNightContext({
    required this.active,
    this.operationalDate,
    this.label,
    this.remainingSlotsCount = 0,
  });

  final bool active;
  final String? operationalDate;
  final String? label;
  final int remainingSlotsCount;

  static const PreviousNightContext inactive =
      PreviousNightContext(active: false);

  factory PreviousNightContext.fromJson(Map<String, dynamic> json) {
    return PreviousNightContext(
      active: json['active'] == true,
      operationalDate: json['operational_date']?.toString(),
      label: json['label']?.toString(),
      remainingSlotsCount:
          (json['remaining_slots_count'] as num?)?.toInt() ?? 0,
    );
  }
}
