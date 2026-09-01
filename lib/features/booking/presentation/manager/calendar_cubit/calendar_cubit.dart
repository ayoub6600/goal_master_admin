import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_state.dart';
import 'package:intl/intl.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final BookingRepo bookingRepo;

  CalendarCubit(this.bookingRepo)
      : super(CalendarInitial(
          selectedDay: DateTime.now(),
          focusedDay: DateTime.now(),
          selectedEvents: {},
        ));

  void updateSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    emit(state.copyWith(
      selectedDay: selectedDay,
      focusedDay: focusedDay,
    ));
    print("تم تحديد التاريخ: ${selectedDay.toLocal()}");
  }

  /// Load the whole night the manager picked.
  ///
  /// `employeeId` is gone from the signature: the time band is an internal
  /// scheduling detail the server resolves per slot. The selected day is the
  /// OPERATIONAL night, so slots after midnight come back carrying the
  /// following calendar date — and this cubit never adds a day to anything.
  Future<void> listNightSlots({
    required int branchId,
    required int serviceId,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(state.selectedDay);

    emit(TimeLoading(
      selectedDay: state.selectedDay,
      focusedDay: state.focusedDay,
      selectedEvents: state.selectedEvents,
      selectedSlot: state.selectedSlot,
    ));

    final result = await bookingRepo.listNightSlots(
      branchId: branchId,
      serviceId: serviceId,
      operationalDate: formattedDate,
    );

    result.fold(
      (failure) => emit(TimeFailure(
        message: failure.errMessage,
        selectedDay: state.selectedDay,
        focusedDay: state.focusedDay,
        selectedEvents: state.selectedEvents,
        selectedSlot: state.selectedSlot,
      )),
      (night) => emit(TimeSuccess(
        night: night,
        selectedDay: state.selectedDay,
        focusedDay: state.focusedDay,
        selectedEvents: state.selectedEvents,
        // A new night invalidates any slot picked on the previous one:
        // deliberately not carried over.
      )),
    );
  }

  /// Ask the server whether the night already in progress is still bookable.
  ///
  /// Returns [PreviousNightContext.inactive] on failure: an unreachable
  /// endpoint should hide an extra affordance, never block the date step.
  Future<PreviousNightContext> loadPreviousNight({
    required int branchId,
    required int serviceId,
  }) async {
    final result = await bookingRepo.previousNightContext(
      branchId: branchId,
      serviceId: serviceId,
    );

    return result.fold(
      (_) => PreviousNightContext.inactive,
      (context) => context,
    );
  }

  /// Record the slot the manager tapped, verbatim.
  ///
  /// The old path split the clock string and rebuilt a DateTime on the browsed
  /// night's year/month/day, then forced the end to start + 1 hour. That put
  /// every after-midnight slot a day early and silently rewrote the duration
  /// of any service that is not sixty minutes. Nothing is reconstructed here.
  void selectSlot(OperationalSlot slot) {
    emit(state.copyWith(selectedSlot: slot));
  }

  /// Drop the current selection — used when the night changes underneath it.
  void clearSlot() {
    final s = state;
    if (s is TimeSuccess) {
      emit(TimeSuccess(
        night: s.night,
        selectedDay: s.selectedDay,
        focusedDay: s.focusedDay,
        selectedEvents: s.selectedEvents,
      ));
    }
  }

  void addEvent(DateTime day, dynamic event) {
    final newEvents = Map<DateTime, List<dynamic>>.from(state.selectedEvents);
    if (!newEvents.containsKey(day)) {
      newEvents[day] = [];
    }
    newEvents[day]!.add(event);
    emit(state.copyWith(selectedEvents: newEvents));
  }
}
