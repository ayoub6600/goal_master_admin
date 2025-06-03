import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_loading_widget.dart';
import 'package:goal_master_admin/core/components/empty_loading.dart';
import 'package:goal_master_admin/core/components/error_state_widget.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/items_user_call.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CustomerViewbody extends StatefulWidget {
  const CustomerViewbody({super.key});

  @override
  State<CustomerViewbody> createState() => _CustomerViewbodyState();
}

class _CustomerViewbodyState extends State<CustomerViewbody> {
  bool _firstBuild = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstBuild) {
      context.read<CustomerCubit>().loadFirstPageManually();
      _firstBuild = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'العملاء',
      allowBack: true,
      child: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoaded) {
            return PagedListView<int, Customer>.separated(
              padding: EdgeInsets.only(bottom: 100.h),
              pagingController: state.pagingController,
              builderDelegate: PagedChildBuilderDelegate<Customer>(
                itemBuilder: (context, customer, index) {
                  return GestureDetector(
                    onTap: () {
                      push(
                        RoutesKeys.kItemsUserDetainsView,
                        context,
                        extra: {
                          'bookingId': customer.id.toString(),
                          'customer': customer,
                        },
                      );
                    },
                    child: ItemsUserCall(customer: customer),
                  );
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
                  return const CustomerListLoading();
                },
                newPageProgressIndicatorBuilder: (context) {
                  return const CustomerListLoading();
                },
                noItemsFoundIndicatorBuilder: (context) {
                  return const EmptyLoading(
                    image: Assets.imagesPngImagePaper,
                    title: "لا يوجد عملاء",
                  );
                },
              ),
              separatorBuilder: (_, __) => HeightSpace(2.h),
            );
          } else if (state is CustomerError) {
            return ErrorStateWidget(
              errorMessage: state.message,
              onRetryPressed: () {
                context.read<CustomerCubit>().refresh();
              },
            );
          }

          return const CustomerListLoading();
        },
      ),
    );
  }
}

class CustomerListLoading extends StatelessWidget {
  const CustomerListLoading({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.grey.shade300,
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16.w),
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
                      height: 14.h,
                      width: 120.w,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
