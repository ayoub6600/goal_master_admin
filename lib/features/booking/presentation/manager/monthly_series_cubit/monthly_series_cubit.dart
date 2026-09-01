import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';

part 'monthly_series_state.dart';

/// The plan behind «حجز شهري».
///
/// Turning the switch on used to set a flag and nothing else: the manager
/// pressed confirm and found out afterwards, from a generic refusal, that one
/// of the four weeks was taken. This loads the actual plan the moment the
/// switch goes on, so what will be created is on screen before anything is.
///
/// It owns no recurrence logic of its own. Weeks, conflicts and the slots a
/// taken week can move to all come from the same preview endpoint the customer
/// app uses; this holds the manager's choices and asks again.
class MonthlySeriesCubit extends Cubit<MonthlySeriesState> {
  MonthlySeriesCubit(this.bookingRepo) : super(const MonthlySeriesState());

  final BookingRepo bookingRepo;

  /// Rises on every load. A response whose token is stale is discarded — the
  /// manager may resolve two weeks quickly, and an earlier reply landing last
  /// would silently undo the newer choice.
  int _token = 0;

  int _branchId = 0;
  int _serviceId = 0;
  int? _customerId;
  BookingOccurrence? _anchor;

  /// Called when the switch goes on, and again whenever the anchor changes.
  Future<void> open({
    required int branchId,
    required int serviceId,
    required BookingOccurrence anchor,
    int? customerId,
  }) async {
    _branchId = branchId;
    _serviceId = serviceId;
    _customerId = customerId;
    _anchor = anchor;

    emit(const MonthlySeriesState(enabled: true, isLoading: true));
    await _load();
  }

  /// Switch off — the booking becomes a single appointment again, and any
  /// choices made here are dropped rather than left to apply invisibly.
  void disable() {
    _token++;
    emit(const MonthlySeriesState());
  }

  Future<void> reload() async {
    if (!state.enabled || _anchor == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _load();
  }

  Future<void> _load() async {
    final anchor = _anchor;
    if (anchor == null) return;

    final token = ++_token;

    final result = await bookingRepo.previewSeries(
      branchId: _branchId,
      employeeId: anchor.employeeId,
      serviceId: _serviceId,
      // The anchor is the occurrence the manager selected, so the recurrence
      // steps from the real appointment — never from the operational night
      // they were browsing when they picked it.
      date: anchor.serviceDate,
      startTime: anchor.startTime,
      endTime: anchor.endTime,
      startAt: anchor.startAtWire,
      endAt: anchor.endAtWire,
      customerId: _customerId,
      // The manager holds four agreed weekly positions; a taken one is moved,
      // never dropped in favour of a later week.
      strictPositions: true,
      // Every move the manager has made so far, re-sent each time so the
      // preview describes the FINAL schedule rather than the original clash.
      replacements: state.replacementPayload,
    );

    if (token != _token) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.errMessage,
      )),
      (preview) => emit(state.copyWith(
        isLoading: false,
        preview: preview,
        clearError: true,
      )),
    );
  }

  /// Move one position of the series to another slot.
  ///
  /// A MOVE, not an addition: the choice is keyed on the position's original
  /// date, and the server puts it back in that same position. Four
  /// appointments before, four after.
  Future<void> chooseReplacement(PreviewDate position, ReplacementSlot slot) async {
    final preview = state.preview;
    if (preview == null) return;

    final updated = preview.dates
        .map((d) => d.date == position.date ? d.copyWith(chosenReplacement: slot) : d)
        .toList();

    // Shown immediately, then confirmed by the server's own answer — the
    // manager should not watch a spinner to see their own tap register.
    emit(state.copyWith(
      preview: preview.copyWith(dates: updated),
      choices: {...state.choices, position.date: slot},
      isLoading: true,
    ));

    await _load();
  }

  Future<void> clearReplacement(PreviewDate position) async {
    final preview = state.preview;
    if (preview == null) return;

    final updated = preview.dates
        .map((d) => d.date == position.date ? d.copyWith(clearChoice: true) : d)
        .toList();

    final choices = Map<String, ReplacementSlot>.from(state.choices)
      ..remove(position.date);

    emit(state.copyWith(
      preview: preview.copyWith(dates: updated),
      choices: choices,
      isLoading: true,
    ));

    await _load();
  }
}
