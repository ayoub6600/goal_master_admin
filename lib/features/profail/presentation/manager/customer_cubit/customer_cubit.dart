// customer_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'customer_state.dart';

// class CustomerCubit extends Cubit<CustomerState> {
//   final ProfileRepo repo;

//   CustomerCubit(this.repo) : super(CustomerInitial());

//   Future<void> fetchCustomers() async {
//     emit(CustomerLoading());
//     final result = await repo.getCustomer();
//     result.fold(
//       (failure) => emit(CustomerError(failure.errMessage)),
//       (data) => emit(CustomerLoaded(data)),
//     );
//   }
//}
// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:goal_master/features/booking/data/model/booking_history_response.dart';
// import 'package:goal_master/features/booking/data/repo/booking_repo.dart';
// import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

// part 'booking_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final ProfileRepo bookingRepo;
  late final PagingController<int, Customer> _pagingController;
  bool _now = true; // <--- add this

  CustomerCubit({
    required this.bookingRepo,
  }) : super(CustomerInitial()) {
    _pagingController = PagingController<int, Customer>(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    emit(CustomerLoaded(pagingController: _pagingController));
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final result = await bookingRepo.getCustomer(
        pageKey,
      );

      result.fold(
        (failure) {
          _pagingController.error = failure.errMessage;
          emit(CustomerError(failure.errMessage));
        },
        (response) {
          final booking = response.data ?? [];
          final isLastPage = pageKey >= (response.lastPage ?? 1);

          if (isLastPage) {
            _pagingController.appendLastPage(booking);
          } else {
            final nextPageKey = pageKey + 1;
            _pagingController.appendPage(booking, nextPageKey);
          }
        },
      );
    } catch (error) {
      _pagingController.error = error.toString();
      emit(CustomerError(error.toString()));
    }
  }

  void setNow(bool value) {
    _now = value;
    print("-------->now: $value    ${_now}");
    _pagingController.refresh();
  }

  void refresh() {
    _pagingController.refresh();
  }

  @override
  Future<void> close() {
    _pagingController.dispose();
    return super.close();
  }
}
