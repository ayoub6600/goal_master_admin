import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final ProfileRepo repository;

  BookingCubit(this.repository) : super(BookingInitial());

  Future<void> updateMonthlyBooking(
      {required String serviceDate, required String id}) async {
    emit(BookingLoading());
    final result =
        await repository.updateMonthlyBooking(serviceDate: serviceDate, id: id);
    result.fold(
      (failure) => emit(BookingFailure(failure.errMessage)),
      (message) => emit(BookingSuccess(message)),
    );
  }
}
