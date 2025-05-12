import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

part 'update_booking_status_state.dart';

class UpdateBookingStatusCubit extends Cubit<UpdateBookingStatusState> {
  final BookingRepo bookingRepo;

  String? selectedStatus;

  UpdateBookingStatusCubit(this.bookingRepo)
      : super(UpdateBookingStatusInitial());

  void setSelectedStatus(String val) {
    selectedStatus = val;
    emit(UpdateBookingStatusChanged());
  }

  Future<void> updateBookingStatus(int bookingId) async {
    if (selectedStatus == null) {
      emit(UpdateBookingStatusError("يرجى اختيار حالة قبل المتابعة"));
      return;
    }

    emit(UpdateBookingStatusLoading());

    final result =
        await bookingRepo.updateStatusBooking(bookingId, selectedStatus!);

    result.fold(
      (failure) => emit(UpdateBookingStatusError(failure.errMessage)),
      (message) => emit(UpdateBookingStatusSuccess(message)),
    );
  }
}
