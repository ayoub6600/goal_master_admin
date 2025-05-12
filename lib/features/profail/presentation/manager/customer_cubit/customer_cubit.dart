// customer_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final ProfileRepo bookingRepo;
  late final PagingController<int, Customer> _pagingController;
  bool _now = true; // <--- add this
  final List<Customer> customers = [];
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
          final fetchedCustomers = response.data ?? [];
          customers.addAll(fetchedCustomers);
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
    customers.clear();
    _pagingController.refresh();
  }

  @override
  Future<void> close() {
    _pagingController.dispose();
    return super.close();
  }
}
