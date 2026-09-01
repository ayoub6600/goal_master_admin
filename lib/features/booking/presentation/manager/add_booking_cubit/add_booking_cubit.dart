import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/created_series.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';


part 'add_booking_state.dart';

class AddBookingCubit extends Cubit<AddBookingState> {
  AddBookingCubit(this.bookingRepo) : super(AddBookingInitial());

  final BookingRepo bookingRepo;
  /// Cash, pre-selected.
  ///
  /// It used to start at 0 — not a valid `cmn_payment_types` id — so a manager
  /// who never tapped the single available option had their booking refused by
  /// a validation rule rather than told anything useful. There is exactly one
  /// supported method in this flow; making the manager tap it to make the
  /// payload valid was never a choice, only a tax.
  int _paymentType = 1; // PaymentType::LocalPayment
  int _isMonthly = 0;
  void setPaymentType(int value) {
    _paymentType = value;
  }

  void setIsMonthly(bool value) {
    _isMonthly = value ? 1 : 0;
  }

  /// Whether the booking just created is a recurring one, so the success
  /// screen can word itself correctly.
  bool get isMonthly => _isMonthly == 1;

  final TextEditingController reviewController = TextEditingController();

  /// Derived from the booking status and the authoritative total, never typed.
  /// A free-text field beside the status buttons could contradict them; this
  /// cannot.
  String _paidAmount = '0';

  void setPaidAmount(String value) {
    _paidAmount = value;
  }

  String get paidAmount => _paidAmount;

  /// Create the booking the manager just reviewed.
  ///
  /// Every date and time comes from [occurrence] — the slot the server offered
  /// — and none from the operational night being browsed. The band travels on
  /// the occurrence too, because the fee is keyed on it: sending an evening
  /// band for an after-midnight slot would charge the wrong rate.
  Future<void> addBooking({
    required int serviceId,
    required BookingOccurrence occurrence,
    required int customerId,
    required String? status,
    required String phone,
    required String fullname,

    /// Set only when the manager has just approved a plan that skips a taken
    /// week. Left null on a first attempt, so a skip can never happen without
    /// them asking for it.
    String? approvedPlanSignature,

    /// Weeks the manager moved. Each MOVES one position of the series rather
    /// than adding to it, so four appointments stay four.
    List<Map<String, dynamic>> replacements = const [],
  }) async {
    emit(AddBookingLoading());

    int clubId = SharedPreferenceUtil.getInt(PrefKey.clubId);
    if (!_validateBookingData(
      employeeId: occurrence.employeeId,
      serviceId: serviceId,
      status: status,
      occurrence: occurrence,
    )) return;

    final result = await bookingRepo.addBooking(
      branchId: clubId,
      employeeId: occurrence.employeeId,
      serviceId: serviceId,
      paymentType: _paymentType,
      date: occurrence.serviceDate,
      startTime: occurrence.startTime,
      endTime: occurrence.endTime,
      startAt: occurrence.startAtWire,
      endAt: occurrence.endAtWire,
      fullName: fullname,
      phone: phone,
      state: '1',
      isMonthly: _isMonthly,
      customerId: customerId,
      review: "",
      paidAmount: _paidAmount,
      status: status ?? "",
      approvedPlanSignature: approvedPlanSignature,
      replacements: replacements,
    );

    result.fold(
      (failure) {
        if (failure is SeriesConflictFailure) {
          emit(AddBookingSeriesConflict(
            message: failure.errMessage,
            conflicts: failure.conflicts,
            canSkipAndExtend: failure.canSkipAndExtend,
            planSignature: failure.planSignature,
            proposedDates: failure.proposedDates,
            skippedDates: failure.skippedDates,
            targetOccurrenceCount: failure.targetOccurrenceCount,
            planChanged: failure.planChanged,
          ));
        } else {
          emit(AddBookingFailure(massage: failure.errMessage));
        }
      },
      (data) => emit(AddBookingSuccess(massage: data.message, series: data.series)),
    );
  }

  bool _validateBookingData({
    required int employeeId,
    required int serviceId,
    required String? status,
    required BookingOccurrence occurrence,
  }) {
    if (employeeId == 0 || serviceId == 0) {
      emit(
          const AddBookingFailure(massage: "يرجى اختيار جميع الحقول المطلوبة"));
      return false;
    }

    if (status == null || status.isEmpty) {
      emit(const AddBookingFailure(massage: "يرجى اختيار حالة الحجز"));
      return false;
    }

    if (_paymentType != 1) {
      emit(const AddBookingFailure(massage: "يرجى اختيار وسيلة دفع صحيحة"));
      return false;
    }

    // The only thing worth checking on the device: that the occurrence runs
    // forwards. How LONG a slot may be is the venue's own configuration —
    // this used to demand sixty minutes, which would have refused the
    // half-hour services the schedule already supports. The server owns that
    // rule and the slot came from the server.
    if (!occurrence.endAt.isAfter(occurrence.startAt)) {
      emit(const AddBookingFailure(massage: "تنسيق الوقت غير صالح"));
      return false;
    }

    return true;
  }
}
