import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

part 'add_customer_state.dart';

class AddCustomerCubit extends Cubit<AddCustomerState> {
  final BookingRepo bookingRepo;

  AddCustomerCubit(this.bookingRepo) : super(AddCustomerInitial());

  Future<void> addCustomer({
    required String fullName,
    required String phone,
  }) async {
    emit(AddCustomerLoading());

    final result = await bookingRepo.addCustomer(
      fullName: fullName,
      phone: phone,
    );

    result.fold(
      (failure) => emit(AddCustomerFailure(message: failure.errMessage)),
      (customerId) => emit(AddCustomerSuccess(customerId: customerId)),
    );
  }
}
