import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:goal_master_admin/core/components/custom_loading_widget.dart';
import 'package:goal_master_admin/core/components/empty_loading.dart';
import 'package:goal_master_admin/core/components/error_state_widget.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_history_response.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomerView extends StatelessWidget {
  const CustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomerViewbody();
  }
}

class CustomerViewbody extends StatelessWidget {
  const CustomerViewbody({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'العملاء',
      allowBack: true,
      child: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoaded) {
            return PagedListView<int, Customer>.separated(
              padding: EdgeInsets.only(
                bottom: 100.h,
              ),
              pagingController: state.pagingController,
              builderDelegate: PagedChildBuilderDelegate<Customer>(
                itemBuilder: (context, booking, index) {
                  final customer = booking;
                  return ListTile(
                    leading: CircleAvatar(child: Text(customer.fullName[0])),
                    title: Text(customer.fullName),
                    subtitle: Text(customer.phoneNo),
                    trailing: Icon(
                      customer.phoneVerified == 1
                          ? Icons.verified
                          : Icons.warning,
                      color: customer.phoneVerified == 1
                          ? Colors.green
                          : Colors.red,
                    ),
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
                  return EmptyLoading(
                    image: Assets.imagesPngImagePaper,
                    title: "لا يوجد عملاء",
                  );
                },
              ),
              separatorBuilder: (_, __) => HeightSpace(16.h),
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
