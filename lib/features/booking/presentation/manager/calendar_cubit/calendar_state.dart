import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';

/// The booking flow's date and time state.
///
/// Two things live here and they are not the same thing:
///
///   [selectedDay] / [focusedDay] — the OPERATIONAL NIGHT being browsed. A
///   listing key and a grouping key. Never a booking date.
///
///   [selectedSlot] — the occurrence the manager actually picked, exactly as
///   the server described it, carrying its own calendar date, its real end,
///   its band and its price.
///
/// Confusing the two is what booked after-midnight slots a day early.
abstract class CalendarState extends Equatable {
  const CalendarState({
    required this.selectedDay,
    required this.focusedDay,
    required this.selectedEvents,
    this.selectedSlot,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final Map<DateTime, List<dynamic>> selectedEvents;
  final OperationalSlot? selectedSlot;

  CalendarState copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    Map<DateTime, List<dynamic>>? selectedEvents,
    OperationalSlot? selectedSlot,
  });

  @override
  List<Object?> get props => [
        selectedDay,
        focusedDay,
        selectedEvents,
        selectedSlot?.startAt,
        selectedSlot?.endAt,
        selectedSlot?.employeeId,
      ];
}

class CalendarInitial extends CalendarState {
  const CalendarInitial({
    required super.selectedDay,
    required super.focusedDay,
    required super.selectedEvents,
    super.selectedSlot,
  });

  @override
  CalendarInitial copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    Map<DateTime, List<dynamic>>? selectedEvents,
    OperationalSlot? selectedSlot,
  }) {
    return CalendarInitial(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedEvents: selectedEvents ?? this.selectedEvents,
      selectedSlot: selectedSlot ?? this.selectedSlot,
    );
  }
}

class TimeLoading extends CalendarState {
  const TimeLoading({
    required super.selectedDay,
    required super.focusedDay,
    required super.selectedEvents,
    super.selectedSlot,
  });

  @override
  TimeLoading copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    Map<DateTime, List<dynamic>>? selectedEvents,
    OperationalSlot? selectedSlot,
  }) {
    return TimeLoading(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedEvents: selectedEvents ?? this.selectedEvents,
      selectedSlot: selectedSlot ?? this.selectedSlot,
    );
  }
}

class TimeSuccess extends CalendarState {
  const TimeSuccess({
    required this.night,
    required super.selectedDay,
    required super.focusedDay,
    required super.selectedEvents,
    super.selectedSlot,
  });

  final OperationalNight night;

  @override
  TimeSuccess copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    Map<DateTime, List<dynamic>>? selectedEvents,
    OperationalSlot? selectedSlot,
    OperationalNight? night,
  }) {
    return TimeSuccess(
      night: night ?? this.night,
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedEvents: selectedEvents ?? this.selectedEvents,
      selectedSlot: selectedSlot ?? this.selectedSlot,
    );
  }

  @override
  List<Object?> get props => [...super.props, night.operationalDate, night.slots.length];
}

class TimeFailure extends CalendarState {
  const TimeFailure({
    required this.message,
    required super.selectedDay,
    required super.focusedDay,
    required super.selectedEvents,
    super.selectedSlot,
  });

  final String message;

  @override
  TimeFailure copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    Map<DateTime, List<dynamic>>? selectedEvents,
    OperationalSlot? selectedSlot,
  }) {
    return TimeFailure(
      message: message,
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedEvents: selectedEvents ?? this.selectedEvents,
      selectedSlot: selectedSlot ?? this.selectedSlot,
    );
  }

  @override
  List<Object?> get props => [...super.props, message];
}
