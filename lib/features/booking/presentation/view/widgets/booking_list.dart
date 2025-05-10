import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_loading_widget.dart';
import 'package:goal_master_admin/core/components/empty_loading.dart';
import 'package:goal_master_admin/core/components/error_state_widget.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_items.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class BookingList extends StatelessWidget {
  const BookingList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingStateNew>(
      builder: (context, state) {
        if (state is BookingSuccess) {
          return PagedListView<int, BookingItemResponce>.separated(
            padding: EdgeInsets.only(
              bottom: 100.h,
            ),
            pagingController: state.pagingController,
            builderDelegate: PagedChildBuilderDelegate<BookingItemResponce>(
              itemBuilder: (context, booking, index) {
                return BookingItems(booking: booking);
              },
              firstPageErrorIndicatorBuilder: (context) {
                return ErrorStateWidget(
                  errorMessage: state.pagingController.error,
                  onRetryPressed: () {
                    state.pagingController.refresh();
                  },
                );
              },
              newPageErrorIndicatorBuilder: (context) {
                return ErrorStateWidget(
                  errorMessage: state.pagingController.error,
                  onRetryPressed: () {
                    state.pagingController.retryLastFailedRequest();
                  },
                );
              },
              firstPageProgressIndicatorBuilder: (context) {
                return const CustomLoadingWidget();
              },
              newPageProgressIndicatorBuilder: (context) {
                return const CustomLoadingWidget();
              },
              noItemsFoundIndicatorBuilder: (context) {
                return EmptyLoading(
                  image: Assets.imagesPngImagePaper,
                  title: "لا يوجد حجوزات",
                );
              },
            ),
            separatorBuilder: (_, __) => HeightSpace(16.h),
          );
        } else if (state is BookingFailure) {
          print("state.message: ${state.message}");
          return ErrorStateWidget(
            errorMessage: state.message,
            onRetryPressed: () {
              context.read<BookingCubit>().refresh();
            },
          );
        }
        return const CustomLoadingWidget();
      },
    );
  }
}
