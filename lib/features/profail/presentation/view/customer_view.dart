import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:goal_master_admin/core/components/custom_loading_widget.dart';
import 'package:goal_master_admin/core/components/empty_loading.dart';
import 'package:goal_master_admin/core/components/error_state_widget.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_history_response.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  return ItemsUserCall(
                    customer: customer,
                  );

                  // ListTile(
                  //   leading: CircleAvatar(child: Text(customer.fullName[0])),
                  //   title: Text(customer.fullName),
                  //   subtitle: Text(customer.phoneNo),
                  //   trailing: Icon(
                  //     customer.phoneVerified == 1
                  //         ? Icons.verified
                  //         : Icons.warning,
                  //     color: customer.phoneVerified == 1
                  //         ? Colors.green
                  //         : Colors.red,
                  //   ),
                  // );
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

class ItemsUserCall extends StatelessWidget {
  const ItemsUserCall({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(
            image: AssetImage(Assets.imagesPngImageBackgroundLogin),
            fit: BoxFit.cover),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(child: Text(customer.fullName[0])),
          WidthSpace(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  style: AppTextStyles.font18Bold.copyWith(color: Colors.white),
                ),
                HeightSpace(8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => launchPhoneCall(customer.phoneNo),
                      child: Text(
                        customer.phoneNo,
                        style: AppTextStyles.font16Bold.copyWith(
                          color: Colors.grey[200],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    //  WidthSpace(8.w),
                  ],
                ),
              ],
            ),
          ),
          WidthSpace(16.w),
          GestureDetector(
            onTap: () => launchWhatsApp(customer.phoneNo),
            child: Image.asset(
              Assets.imagesPngImageGlobalRefresh,
              width: 24.w,
              height: 24.w,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}

void launchPhoneCall(String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    throw 'لا يمكن الاتصال بـ $phoneNumber';
  }
}

String formatToInternationalPhone(String phone, {String countryCode = '966'}) {
  // إزالة أي محارف غير أرقام
  phone = phone.replaceAll(RegExp(r'[^\d]'), '');

  // إذا بدأ بصفر، نحذفه ونضيف رمز الدولة
  if (phone.startsWith('0')) {
    phone = phone.substring(1);
  }

  // إذا لم يبدأ برمز الدولة، نضيفه
  if (!phone.startsWith(countryCode)) {
    phone = countryCode + phone;
  }

  return phone;
}

Future<void> launchWhatsApp(String rawPhone) async {
  final String phone =
      formatToInternationalPhone(rawPhone); // ← يتم التنسيق هنا

  final Uri uri = Uri.parse("https://wa.me/$phone");
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'لا يمكن فتح واتساب لهذا الرقم: $phone';
  }
}
