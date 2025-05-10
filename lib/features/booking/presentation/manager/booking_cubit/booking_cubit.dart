import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingStateNew> {
  final BookingRepo bookingRepo;
  late final PagingController<int, BookingItemResponce> _pagingController;

  BookingCubit({
    required this.bookingRepo,
  }) : super(BookingInitial()) {
    _pagingController =
        PagingController<int, BookingItemResponce>(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    emit(BookingSuccess(pagingController: _pagingController));
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final result = await bookingRepo.getBooking(
        pageKey,
      );

      result.fold(
        (failure) {
          _pagingController.error = failure.errMessage;
          emit(BookingFailure(message: failure.errMessage));
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
      emit(BookingFailure(message: error.toString()));
    }
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
