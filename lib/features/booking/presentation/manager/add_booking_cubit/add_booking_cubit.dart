import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

import 'package:intl/intl.dart';

part 'add_booking_state.dart';

class AddBookingCubit extends Cubit<AddBookingState> {
  AddBookingCubit(this.bookingRepo) : super(AddBookingInitial());

  final BookingRepo bookingRepo;
  int _paymentType = 0; // default is cash
  int _isMonthly = 0;
  void setPaymentType(int value) {
    _paymentType = value;
  }

  void setIsMonthly(bool value) {
    _isMonthly = value ? 1 : 0;
  }

  final TextEditingController reviewController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();

  Future<void> addBooking({
    required int employeeId,
    required int serviceId,
    required String date,
    required int customerId,
    required String status,
    required String phone,
    required String fullname,
    required dynamic startTime, // String or DateTime
    required dynamic endTime, // String or DateTime
  }) async {
    emit(AddBookingLoading());

    String formattedDate = _formatDate(date);

    // Convert time to "HH:mm:ss" based on type
    String formattedStartTime = _formatTime(startTime);
    String formattedEndTime = _formatTime(endTime);

    int clubId = SharedPreferenceUtil.getInt(PrefKey.clubId); // تأكد من المفتاح
    if (!_validateBookingData(
      employeeId: employeeId,
      serviceId: serviceId,
      date: formattedDate,
      startTime: startTime,
      endTime: endTime,
    )) return;

    final result = await bookingRepo.addBooking(
      branchId: clubId,
      employeeId: employeeId,
      serviceId: serviceId,
      paymentType: _paymentType,
      date: formattedDate,
      startTime: formattedStartTime,
      endTime: formattedEndTime,
      fullName: fullname,
      phone: phone,
      //   phone: '0916776611',
      state: '1',
      isMonthly: _isMonthly,
      customerId: customerId,
      review: "",
      paidAmount: paidAmountController.text,
      status: status,
    );

    result.fold(
      (failure) => emit(AddBookingFailure(massage: failure.errMessage)),
      (data) => emit(AddBookingSuccess(massage: data)),
    );
  }

  /// Format time if it's DateTime, otherwise return as-is.
  String _formatTime(dynamic time) {
    if (time is String) {
      return time;
    } else if (time is DateTime) {
      return DateFormat("HH:mm:ss").format(time);
    } else {
      throw FormatException("Invalid time format");
    }
  }

  /// Format date to yyyy-MM-dd
  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  bool _validateBookingData({
    required int employeeId,
    required int serviceId,
    required String date,
    required dynamic startTime,
    required dynamic endTime,
  }) {
    if (employeeId == 0 || serviceId == 0) {
      emit(
          const AddBookingFailure(massage: "يرجى اختيار جميع الحقول المطلوبة"));
      return false;
    }

    if (date.isEmpty || startTime == null || endTime == null) {
      emit(const AddBookingFailure(massage: "يرجى اختيار التاريخ والوقت"));
      return false;
    }

    if (_paymentType != 1 && _paymentType != 4) {
      emit(const AddBookingFailure(massage: "يرجى اختيار وسيلة دفع صحيحة"));
      return false;
    }

    try {
      DateTime start = (startTime is DateTime)
          ? startTime
          : DateFormat("HH:mm:ss").parse(startTime);
      DateTime end = (endTime is DateTime)
          ? endTime
          : DateFormat("HH:mm:ss").parse(endTime);

      final difference = end.difference(start);

      if (difference.inMinutes < 60) {
        emit(const AddBookingFailure(
            massage: "يجب أن يكون الحجز لمدة ساعة على الأقل"));
        return false;
      }
    } catch (e) {
      emit(const AddBookingFailure(massage: "تنسيق الوقت غير صالح"));
      return false;
    }

    return true;
  }
}
