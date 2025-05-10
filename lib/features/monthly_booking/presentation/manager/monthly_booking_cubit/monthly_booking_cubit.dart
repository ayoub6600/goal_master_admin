import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'monthly_booking_state.dart';

class MonthlyBookingCubit extends Cubit<MonthlyBookingState> {
  final MonthlyBookingRepo bookingRepo;
  late final PagingController<int, MonthlyBookingResponse> _pagingController;

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
    try {
      final result = await bookingRepo.listMonthlyBooking(pageKey);

      result.fold(
        (failure) {
          _pagingController.error = failure.errMessage;
          emit(MonthlyBookingError(failure.errMessage));
        },
        (response) {
          final booking = response;
          final isLastPage = booking.length < 10; // Modify as needed

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
      emit(MonthlyBookingError(error.toString()));
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
