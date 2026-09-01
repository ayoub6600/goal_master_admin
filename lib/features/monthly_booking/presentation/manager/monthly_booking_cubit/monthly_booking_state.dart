part of 'monthly_booking_cubit.dart';

abstract class MonthlyBookingState {}

class MonthlyBookingInitial extends MonthlyBookingState {}

class MonthlyBookingLoading extends MonthlyBookingState {}

class MonthlyBookingLoaded extends MonthlyBookingState {
  MonthlyBookingLoaded({
    required this.groups,
    required this.total,
    required this.query,
    required this.filter,
  });

  /// Recurring bookings after search and filter.
  final List<MonthlySeriesGroup> groups;

  /// How many exist in total, so the screen can tell "you have none" apart
  /// from "none match what you typed".
  final int total;

  final String query;
  final SeriesFilter filter;

  bool get isFiltered => query.isNotEmpty || filter != SeriesFilter.all;
}

class MonthlyBookingError extends MonthlyBookingState {
  MonthlyBookingError(this.message);

  final String message;
}
