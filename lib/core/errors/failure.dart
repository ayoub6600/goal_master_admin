class Failure {
  final String errMessage;
  final List<String>? details;

  Failure({required this.errMessage, this.details});
}

/// A recurring booking ("حجز شهري") refused because one or more of its weeks
/// is taken.
///
/// A dedicated type because a flattened message cannot be rendered as a list,
/// and because the refusal may carry a workable alternative: skip the taken
/// week and extend, so the customer still gets four bookings. Nothing happens
/// until the manager approves that exact plan.
class SeriesConflictFailure extends Failure {
  final List<ConflictedDate> conflicts;
  final bool canSkipAndExtend;

  /// The fingerprint of the offered plan. Sent back on approval so the series
  /// can only ever be created on the dates that were displayed.
  final String planSignature;

  /// The dates the offer would actually book.
  final List<String> proposedDates;
  final List<String> skippedDates;
  final int targetOccurrenceCount;

  /// True when this is a re-approval because the dates moved since the last
  /// one. Nothing was booked either way.
  final bool planChanged;

  SeriesConflictFailure({
    required String errMessage,
    required this.conflicts,
    this.canSkipAndExtend = false,
    this.planSignature = '',
    this.proposedDates = const [],
    this.skippedDates = const [],
    this.targetOccurrenceCount = 4,
    this.planChanged = false,
  }) : super(errMessage: errMessage);
}

class ConflictedDate {
  final String date;
  final String startTime;
  final String message;

  const ConflictedDate({
    required this.date,
    required this.startTime,
    required this.message,
  });
}
