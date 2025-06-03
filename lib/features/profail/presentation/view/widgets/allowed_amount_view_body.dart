import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/allowed_amount_cubit/allowed_amount_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/allowed_amount_card.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AllowedAmountViewBody extends StatelessWidget {
  const AllowedAmountViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllowedAmountCubit, AllowedAmountState>(
      builder: (context, state) {
        if (state is AllowedAmountLoaded) {
          return PagedListView<int, AllowedAmountData>(
            pagingController: state.pagingController,
            padding: const EdgeInsets.all(16),
            builderDelegate: PagedChildBuilderDelegate<AllowedAmountData>(
              itemBuilder: (context, item, index) =>
                  AllowedAmountCard(item: item),
              noItemsFoundIndicatorBuilder: (_) =>
                  const Center(child: Text("لا توجد بيانات")),
              firstPageErrorIndicatorBuilder: (_) =>
                  const Center(child: Text("حدث خطأ في تحميل البيانات")),
            ),
          );
        }
        return AllowedAmountListLoading();
      },
    );
  }
}

class AllowedAmountListLoading extends StatelessWidget {
  const AllowedAmountListLoading({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14.h,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 12.h,
                      width: 140.w,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 12.h,
                      width: 80.w,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
