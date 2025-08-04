import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/empty_loading.dart';
import 'package:goal_master_admin/core/components/error_state_widget.dart';
import 'package:goal_master_admin/core/components/error_widgets.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_items.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

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
                return const BookingListLoading();
              },
              newPageProgressIndicatorBuilder: (context) {
                return const BookingListLoading();
              },
              noItemsFoundIndicatorBuilder: (context) {
                return const EmptyLoading(
                  image: Assets.imagesPngImagePaper,
                  title: "لا يوجد حجوزات",
                );
              },
            ),
            separatorBuilder: (_, __) => HeightSpace(16.h),
          );
        } else if (state is BookingFailure) {
          print("state.message: ${state.message}");
          return AppErrorView(
            message: state.message,
          );
        }
        return const BookingListLoading(
          itemCount: 4,
        );
      },
    );
  }
}

class BookingListLoading extends StatelessWidget {
  const BookingListLoading({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => Shimmer(
          duration: const Duration(seconds: 2),
          interval: const Duration(seconds: 0),
          color: Colors.white,
          colorOpacity: 0,
          enabled: true,
          direction: const ShimmerDirection.fromLTRB(),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary),
              color: Colors.grey.shade300,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Container(
                        height: 14.h,
                        width: 100.w,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                HeightSpace(10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 30.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      Container(
                        height: 30.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12.r),
                            bottomRight: Radius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                HeightSpace(16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      WidthSpace(10.w),
                      Container(
                        height: 14.h,
                        width: 120.w,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                HeightSpace(16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            WidthSpace(10.w),
                            Container(
                              height: 14.h,
                              width: 60.w,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            WidthSpace(10.w),
                            Container(
                              height: 14.h,
                              width: 100.w,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                HeightSpace(12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
