import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'monthly_booking_state.dart';

class MonthlyBookingCubit extends Cubit<MonthlyBookingState> {
  final MonthlyBookingRepo bookingRepo;
  late final PagingController<int, MonthlyBookingResponse> _pagingController;
  bool _isDisposed = false;

  PagingController<int, MonthlyBookingResponse> get pagingController =>
      _pagingController;

  MonthlyBookingCubit({
    required this.bookingRepo,
  }) : super(MonthlyBookingInitial()) {
    _pagingController =
        PagingController<int, MonthlyBookingResponse>(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    emit(MonthlyBookingLoaded(pagingController: _pagingController));
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isDisposed) return;

    try {
      final result = await bookingRepo.listMonthlyBooking(pageKey);
      if (_isDisposed) return;

      result.fold(
        (failure) {
          if (_isDisposed) return;
          _pagingController.error = failure.errMessage;
          emit(MonthlyBookingError(failure.errMessage));
        },
        (response) {
          if (_isDisposed) return;
          final bookings = response;
          final isLastPage = bookings.length < 10;

          if (isLastPage) {
            _pagingController.appendLastPage(bookings);
          } else {
            final nextPageKey = pageKey + 1;
            _pagingController.appendPage(bookings, nextPageKey);
          }
        },
      );
    } catch (error) {
      if (_isDisposed) return;
      _pagingController.error = error.toString();
      emit(MonthlyBookingError(error.toString()));
    }
  }

  void refresh() {
    if (_isDisposed) return;
    _pagingController.refresh();
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _pagingController.dispose();
    return super.close();
  }
}
