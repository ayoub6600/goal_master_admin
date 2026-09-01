part of 'add_booking_cubit.dart';

sealed class AddBookingState extends Equatable {
  const AddBookingState();

  @override
  List<Object> get props => [];
}

final class AddBookingInitial extends AddBookingState {}

final class AddBookingLoading extends AddBookingState {}

final class AddBookingSuccess extends AddBookingState {
  final String massage;

  /// Present for a recurring booking: the server's own account of what it
  /// created, which the success screen renders instead of the request.
  final CreatedSeries? series;

  const AddBookingSuccess({required this.massage, this.series});

  @override
  List<Object> get props => [massage, series?.seriesId ?? 0];
}

/// A recurring booking clashed, and a workable plan may be on offer: skip the
/// taken week and extend, so the count still comes to four.
///
/// Separate from AddBookingFailure because it is not a dead end — nothing was
/// booked, and the manager has a decision to make.
final class AddBookingSeriesConflict extends AddBookingState {
  final String message;
  final List<ConflictedDate> conflicts;
  final bool canSkipAndExtend;
  final String planSignature;
  final List<String> proposedDates;
  final List<String> skippedDates;
  final int targetOccurrenceCount;

  /// The dates moved since the last approval. Nothing was booked either way.
  final bool planChanged;

  const AddBookingSeriesConflict({
    required this.message,
    required this.conflicts,
    required this.canSkipAndExtend,
    required this.planSignature,
    required this.proposedDates,
    required this.skippedDates,
    required this.targetOccurrenceCount,
    required this.planChanged,
  });

  @override
  List<Object> get props =>
      [message, conflicts.length, canSkipAndExtend, planSignature, planChanged];
}

final class AddBookingFailure extends AddBookingState {
  final String massage;

  const AddBookingFailure({required this.massage});

  @override
  List<Object> get props => [massage];
}
