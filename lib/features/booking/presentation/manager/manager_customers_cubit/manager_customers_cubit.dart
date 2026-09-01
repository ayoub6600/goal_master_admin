import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_customer.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

part 'manager_customers_state.dart';

/// The manager's customer book, searched server-side.
///
/// Replaces a paginated third-party dropdown wired to two endpoints that
/// disagreed about their own contract: browsing paginated without searching,
/// typing searched without paginating, so asking for "page 2" of a search
/// returned the same full list again. One endpoint now, one shape, one page
/// counter.
class ManagerCustomersCubit extends Cubit<ManagerCustomersState> {
  ManagerCustomersCubit(this.bookingRepo)
      : super(const ManagerCustomersState());

  final BookingRepo bookingRepo;

  /// Rises on every new search or refresh. A response whose token no longer
  /// matches is discarded — otherwise a slow request for «مح» could land after
  /// a fast one for «محمد» and repopulate the list with the wrong results.
  int _requestToken = 0;

  Future<void> load({String? search, bool reset = true}) async {
    final term = (search ?? state.search).trim();
    final token = ++_requestToken;

    emit(state.copyWith(
      search: term,
      isLoading: reset,
      isLoadingMore: !reset,
      clearError: true,
      customers: reset ? const [] : null,
      page: reset ? 1 : null,
    ));

    final result = await bookingRepo.managerCustomers(
      search: term.isEmpty ? null : term,
      page: reset ? 1 : state.page + 1,
    );

    if (token != _requestToken) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failure.errMessage,
      )),
      (page) => emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        customers:
            reset ? page.customers : [...state.customers, ...page.customers],
        page: page.currentPage,
        hasMore: page.hasMore,
        total: page.total,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await load(reset: false);
  }

  /// A customer the manager just created.
  ///
  /// Placed at the top and selected immediately. The old flow could not do
  /// this: both customer endpoints required a booking to already exist, so
  /// somebody added seconds earlier was invisible until after their first
  /// booking — which is exactly the booking the manager was in the middle of.
  void adopt(ManagerCustomer customer) {
    emit(state.copyWith(
      customers: [
        customer,
        ...state.customers.where((c) => c.id != customer.id),
      ],
      selected: customer,
    ));
  }

  void select(ManagerCustomer customer) => emit(state.copyWith(selected: customer));
}
