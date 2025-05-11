import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingStateNew> {
  BookingCubit(this.bookingRepo) : super(BookingInitial()) {
    _pagingController =
        PagingController<int, BookingItemResponce>(firstPageKey: 1);
    _pagingController.addPageRequestListener(_fetchPage);
    emit(BookingSuccess(pagingController: _pagingController));
  }

  final BookingRepo bookingRepo;
  late final PagingController<int, BookingItemResponce> _pagingController;

  String? bookingStart;
  String? bookingEnd;
  String? startTime;
  String? endTime;
  String? branchId;
  String? employeeId;
  String? customerId;
  String? status;

  void updateBookingStart(String date) => bookingStart = date;
  void updateBookingEnd(String date) => bookingEnd = date;
  void updateStartTime(String time) => startTime = time;
  void updateEndTime(String time) => endTime = time;
  void updateBranchId(String id) => branchId = id;
  void updateEmployeeId(String id) => employeeId = id;
  void updateCustomerId(String id) => customerId = id;
  void updateStatus(String val) => status = val;

  void clearFilters() {
    bookingStart = null;
    bookingEnd = null;
    startTime = null;
    endTime = null;
    branchId = null;
    employeeId = null;
    customerId = null;
    status = null;
  }

  String formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> filterBooking() async {
    _pagingController.refresh();
  }

  Future<void> resetFilters() async {
    clearFilters();
    _pagingController.refresh();
  }

  Future<void> _fetchPage(int pageKey) async {
    print("status $status");
    try {
      final result = await bookingRepo.getBooking(
        pageKey,
        bookingStart ?? '',
        bookingEnd ?? '',
        branchId,
        employeeId,
        customerId,
        status,
      );

      result.fold(
        (failure) {
          _pagingController.error = failure.errMessage;
          emit(BookingFailure(message: failure.errMessage));
        },
        (response) {
          final bookings = response.data ?? [];
          final isLastPage = pageKey >= (response.lastPage ?? 1);

          if (isLastPage) {
            _pagingController.appendLastPage(bookings);
          } else {
            _pagingController.appendPage(bookings, pageKey + 1);
          }

          emit(BookingSuccess(pagingController: _pagingController));
        },
      );
    } catch (e) {
      _pagingController.error = e.toString();
      emit(BookingFailure(message: e.toString()));
    }
  }

  void refresh() {
    _pagingController.refresh();
  }

  PagingController<int, BookingItemResponce> get pagingController =>
      _pagingController;
}
