import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_booking_items.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_booking_loading.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class MonthlyBookingBody extends StatelessWidget {
  const MonthlyBookingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyBookingCubit, MonthlyBookingState>(
      builder: (context, state) {
        if (state is MonthlyBookingLoaded) {
          return RefreshIndicator(
            onRefresh: () async => state.pagingController.refresh(),
            child: PagedListView<int, MonthlyBookingResponse>(
              pagingController: state.pagingController,
              builderDelegate:
                  PagedChildBuilderDelegate<MonthlyBookingResponse>(
                itemBuilder: (context, booking, index) {
                  return MonthlyBookingItems(booking: booking);
                },
                noItemsFoundIndicatorBuilder: (_) =>
                    const Center(child: Text('لا توجد حجوزات')),
                firstPageProgressIndicatorBuilder: (_) =>
                    const MonthlyBookingLoading(),
                newPageProgressIndicatorBuilder: (_) =>
                    const MonthlyBookingLoading(itemCount: 2),
              ),
            ),
          );
        } else if (state is MonthlyBookingError) {
          return Center(child: Text('حدث خطأ: ${state.message}'));
        } else {
          return const MonthlyBookingLoading();
        }
      },
    );
  }
}
