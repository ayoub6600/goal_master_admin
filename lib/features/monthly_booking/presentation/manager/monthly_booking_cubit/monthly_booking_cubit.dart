import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';

part 'monthly_booking_state.dart';

/// The monthly-booking list.
///
/// Loads once rather than page by page. `getMonthlyBookingList` ignores its
/// `page` parameter and returns every row on each call, so the paged controller
/// this used to drive would ask for page 2, receive the same rows again and
/// append them — any venue with ten or more monthly sessions saw duplicates
/// that grew as it scrolled.
///
/// Because the whole list is in hand, searching and filtering are complete:
/// a manager typing a customer's name is matched against all of their monthly
/// bookings, not only the ones scrolled past so far.
class MonthlyBookingCubit extends Cubit<MonthlyBookingState> {
  MonthlyBookingCubit({required this.bookingRepo})
      : super(MonthlyBookingInitial());

  final MonthlyBookingRepo bookingRepo;

  List<MonthlySeriesGroup> _all = const [];
  String _query = '';
  SeriesFilter _filter = SeriesFilter.all;

  Future<void> load() async {
    emit(MonthlyBookingLoading());

    final result = await bookingRepo.listMonthlyBooking(1);
    if (isClosed) return;

    result.fold(
      (failure) => emit(MonthlyBookingError(failure.errMessage)),
      (rows) {
        _all = MonthlySeriesGroup.from(rows);
        _emitLoaded();
      },
    );
  }

  Future<void> refresh() => load();

  void search(String query) {
    _query = query.trim();
    _emitLoaded();
  }

  void filterBy(SeriesFilter filter) {
    _filter = filter;
    _emitLoaded();
  }

  void _emitLoaded() {
    if (isClosed) return;

    emit(MonthlyBookingLoaded(
      groups: _visible(),
      total: _all.length,
      query: _query,
      filter: _filter,
    ));
  }

  List<MonthlySeriesGroup> _visible() {
    final needle = _query.toLowerCase();

    return _all.where((g) {
      final matchesFilter = switch (_filter) {
        SeriesFilter.all => true,
        SeriesFilter.active => g.isActive,
        SeriesFilter.ended => !g.isActive,
        SeriesFilter.owing => g.remainingAmount > 0 && g.isActive,
      };
      if (!matchesFilter) return false;
      if (needle.isEmpty) return true;

      return g.customerName.toLowerCase().contains(needle) ||
          g.branchName.toLowerCase().contains(needle) ||
          g.customerPhone.contains(needle) ||
          g.reference.toString().contains(needle);
    }).toList();
  }
}

/// The three questions a manager actually asks of this list.
enum SeriesFilter {
  all,
  active,
  ended,
  owing;

  String get label => switch (this) {
        SeriesFilter.all => 'الكل',
        SeriesFilter.active => 'مفعّل',
        SeriesFilter.ended => 'منتهي',
        SeriesFilter.owing => 'عليه مستحقات',
      };
}
