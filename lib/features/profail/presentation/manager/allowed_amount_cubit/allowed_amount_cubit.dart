import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'allowed_amount_state.dart';

class AllowedAmountCubit extends Cubit<AllowedAmountState> {
  final ProfileRepo repo;
  late final PagingController<int, AllowedAmountData> pagingController;
  bool _isDisposed = false;

  AllowedAmountCubit({required this.repo}) : super(AllowedAmountInitial()) {
    pagingController = PagingController(firstPageKey: 1);
    pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    emit(AllowedAmountLoaded(pagingController: pagingController));
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isDisposed) return;

    try {
      final result = await repo.getAllowedAmount(pageKey);
      if (_isDisposed) return;

      result.fold(
        (failure) {
          if (_isDisposed) return;
          pagingController.error = failure.errMessage;
          emit(AllowedAmountError(failure.errMessage));
        },
        (response) {
          if (_isDisposed) return;
          final items = response.data;
          final isLastPage = pageKey >= response.pagination.lastPage;

          if (isLastPage) {
            pagingController.appendLastPage(items);
          } else {
            final nextPageKey = pageKey + 1;
            pagingController.appendPage(items, nextPageKey);
          }
        },
      );
    } catch (error) {
      if (_isDisposed) return;
      pagingController.error = error.toString();
      emit(AllowedAmountError(error.toString()));
    }
  }

  void refresh() {
    if (_isDisposed) return;
    pagingController.refresh();
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    pagingController.dispose();
    return super.close();
  }
}
