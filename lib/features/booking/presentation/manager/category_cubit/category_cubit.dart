import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/features/booking/data/model/category_model.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this.bookingRepo) : super(CategoryInitial());

  final BookingRepo bookingRepo;

  Future<void> listCategory() async {
    emit(CategoryLoading());

    int branchId = SharedPreferenceUtil.getInt(PrefKey.clubId);

    final result = await bookingRepo.listCategory(branchId: branchId);
    result.fold(
      (failure) => emit(CategoryFailure(message: failure.errMessage)),
      (category) => emit(CategorySuccess(categories: category)),
    );
  }
}
