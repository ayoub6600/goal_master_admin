import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/udate_monthly_booking_cubit/udate_monthly_booking_state.dart';

class MonthlyBookingCubit extends Cubit<UpdateMonthlyBookingState> {
  final MonthlyBookingRepo repository;

  MonthlyBookingCubit(this.repository) : super(MonthlyBookingInitial());

  Future<void> updateMonthlyBooking({
    required String serviceDate,
    required String id,
  }) async {
    emit(MonthlyBookingLoading());
    final result = await repository.updateMonthlyBooking(
      serviceDate: serviceDate,
      id: id,
    );

    result.fold(
      (failure) => emit(MonthlyBookingFailure(failure.errMessage)),
      (message) => emit(MonthlyBookingSuccess(message)),
    );
  }
}
