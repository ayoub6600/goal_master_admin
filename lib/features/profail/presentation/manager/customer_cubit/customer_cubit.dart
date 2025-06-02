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
  final Set<int> _fetchedPages = {}; // 🔒 لتفادي تكرار نفس الصفحة
  bool _now = true;

  CustomerCubit({required this.bookingRepo}) : super(CustomerInitial()) {
    _pagingController = PagingController<int, Customer>(firstPageKey: 1);

    // ✅ تأكد أن listener يشتغل مرة واحدة فقط
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
    // 🔒 تفادي تحميل نفس الصفحة مرتين
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

  void setNow(bool value) {
    _now = value;
    print("-------->now: $value    ${_now}");
    customers.clear();
    _fetchedPages.clear(); // 🧼 نرجع كل شيء من أول وجديد
    _pagingController.refresh();
  }

  void refresh() {
    customers.clear();
    _fetchedPages.clear(); // 🧼 نرجع كل شيء من أول وجديد
    _pagingController.refresh();
  }

  @override
  Future<void> close() {
    _pagingController.dispose();
    return super.close();
  }
}
