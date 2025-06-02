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
                  return const CustomLoadingWidget();
                },
                newPageProgressIndicatorBuilder: (context) {
                  return const CustomLoadingWidget();
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

          return const CustomLoadingWidget();
        },
      ),
    );
  }
}
