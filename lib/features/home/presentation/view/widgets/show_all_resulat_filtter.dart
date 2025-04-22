import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_loading_widget.dart';
import 'package:goal_master_admin/core/components/empty_loading.dart';
import 'package:goal_master_admin/core/components/error_state_widget.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/presentation/manager/filter_cubit/filter_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/booking_item.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../data/model/booking_slots_response.dart';

class ShowAllResulatFiltter extends StatelessWidget {
  const ShowAllResulatFiltter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, state) {
        if (state is FilterLoaded) {
          return PagedListView<int, BookingSlot>.separated(
            padding: EdgeInsets.zero,
            pagingController: state.pagingController,
            builderDelegate: PagedChildBuilderDelegate<BookingSlot>(
              itemBuilder: (context, booking, index) {
                return BookingItem(booking: booking);
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
              firstPageProgressIndicatorBuilder: (context) =>
                  const CustomLoadingWidget(),
              newPageProgressIndicatorBuilder: (context) =>
                  const CustomLoadingWidget(),
              noItemsFoundIndicatorBuilder: (context) => EmptyLoading(
                image: Assets.imagesPngImagePaper,
                title: "لا يوجد حجوزات",
              ),
            ),
            separatorBuilder: (_, __) => HeightSpace(16.h),
          );
        } else if (state is FilterError) {
          return ErrorStateWidget(
            errorMessage: state.message,
            onRetryPressed: () {
              context.read<FilterCubit>().filterBooking();
            },
          );
        }

        return const CustomLoadingWidget();
      },
    );
  }
}
