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
  final List<Customer> customers = [];
  final Set<int> _fetchedPages = {};
  bool _now = true;

  CustomerCubit({required this.bookingRepo}) : super(CustomerInitial()) {
    _pagingController = PagingController<int, Customer>(firstPageKey: 1);

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    emit(CustomerLoaded(pagingController: _pagingController));
  }

  Future<void> loadFirstPageManually() async {
    if (customers.isEmpty) {
      emit(CustomerLoading());

      await _fetchPage(1);

      emit(CustomerLoaded(pagingController: _pagingController));
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_fetchedPages.contains(pageKey)) return;
    _fetchedPages.add(pageKey);

    try {
      final result = await bookingRepo.getCustomer(pageKey);

      result.fold(
        (failure) {
          _pagingController.error = failure.errMessage;
          emit(CustomerError(failure.errMessage));
        },
        (response) {
          final fetchedCustomers = response.data ?? [];
          customers.addAll(fetchedCustomers);

          final isLastPage = pageKey >= (response.lastPage ?? 1);

          if (isLastPage) {
            _pagingController.appendLastPage(fetchedCustomers);
          } else {
            _pagingController.appendPage(fetchedCustomers, pageKey + 1);
          }
        },
      );
    } catch (error) {
      _pagingController.error = error.toString();
      emit(CustomerError(error.toString()));
    }
  }

  Future<Either<Failure, List<Customer>>> fetchCustomersForDropdown({
    required int page,
    String? search,
  }) async {
    if (search != null && search.isNotEmpty) {
      final result = await bookingRepo.searchCustomers(search: search);

      return result.fold(
        (failure) => Left(failure),
        (response) => Right(response.data ?? []),
      );
    }

    final result = await bookingRepo.getCustomer(page);

    return result.fold(
      (failure) => Left(failure),
      (response) => Right(response.data ?? []),
    );
  }

  void setNow(bool value) {
    _now = value;
    customers.clear();
    _fetchedPages.clear();
    _pagingController.refresh();
  }

  void refresh() {
    customers.clear();
    _fetchedPages.clear();
    _pagingController.refresh();
  }

  @override
  Future<void> close() {
    _pagingController.dispose();
    return super.close();
  }
}
