import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/udate_monthly_booking_cubit/udate_monthly_booking_state.dart';

class UpdateMonthlyBooking extends Cubit<UpdateMonthlyBookingState> {
  final MonthlyBookingRepo repository;

  UpdateMonthlyBooking(this.repository) : super(UpdateMonthlyBookingInitial());

  Future<void> updateMonthlyBooking({
    required String serviceDate,
    required String id,
  }) async {
    emit(UpdateMonthlyBookingLoading());
    final result = await repository.updateMonthlyBooking(
      serviceDate: serviceDate,
      id: id,
    );

    result.fold(
      (failure) => emit(UpdateMonthlyBookingFailure(failure.errMessage)),
      (message) => emit(UpdateMonthlyBookingSuccess(message)),
    );
  }
}
