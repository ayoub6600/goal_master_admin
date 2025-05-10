import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'allowed_amount_state.dart';

class AllowedAmountCubit extends Cubit<AllowedAmountState> {
  final ProfileRepo repo;
  late final PagingController<int, AllowedAmountData> pagingController;

  AllowedAmountCubit({required this.repo}) : super(AllowedAmountInitial()) {
    pagingController = PagingController(firstPageKey: 1);
    pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    emit(AllowedAmountLoaded(pagingController: pagingController));
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final result = await repo.getAllowedAmount(pageKey);

      result.fold(
        (failure) {
          pagingController.error = failure.errMessage;
          emit(AllowedAmountError(failure.errMessage));
        },
        (response) {
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
      pagingController.error = error.toString();
      emit(AllowedAmountError(error.toString()));
    }
  }

  void refresh() {
    pagingController.refresh();
  }

  @override
  Future<void> close() {
    pagingController.dispose();
    return super.close();
  }
}
