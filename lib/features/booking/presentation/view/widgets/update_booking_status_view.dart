import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down_shimmer_items.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/update_booking_status_cubit/update_booking_status_cubit.dart';

class UpdateBookingStatusView extends StatelessWidget {
  const UpdateBookingStatusView({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateBookingStatusCubit, UpdateBookingStatusState>(
      listener: (context, state) {
        if (state is UpdateBookingStatusSuccess) {
          CustomSuccessToast(toastText: state.message);
          context.read<BookingDetailsCubit>().getBookingInfo();
          Navigator.pop(context);
        } else if (state is UpdateBookingStatusError) {
          showCustomFailureToast(state.message);
        }
      },
      builder: (context, state) {
        final cubit = context.read<UpdateBookingStatusCubit>();

        return Expanded(
          child: ButtonApp(
            text: state is UpdateBookingStatusLoading
                ? "جاري تعديل الحجز"
                : "تعديل الحجز",
            textColor: Colors.white,
            backGround: AppColors.primary,
            onTap: () {
              baseBottomSheet(
                title: "تعديل الحجز",
                context: context,
                child: Column(
                  children: [
                    Text(
                      "هل انت متأكد من تعديل الحجز؟",
                      style: AppTextStyles.font16Regular,
                    ),
                    HeightSpace(20.h),
                    CustomDropDownShimmerNew(
                      label: "الحالة",
                      hint: "اختر الحالة",
                      items: const [
                        {"id": 0, "name_ar": "قيد الانتظار"},
                        {"id": 1, "name_ar": "قيد المعالجة"},
                        {"id": 2, "name_ar": "موافَق عليه"},
                        {"id": 3, "name_ar": "ملغي"},
                        {"id": 4, "name_ar": "مكتمل"},
                      ],
                      selectedValue: cubit.selectedStatus?.toString(),
                      onChanged: (val) {
                        cubit.setSelectedStatus(val!);
                      },
                    ),
                    HeightSpace(20.h),
                    Row(
                      children: [
                        Expanded(
                          child: ButtonApp(
                            backGround: AppColors.grey,
                            text: "الغاء",
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        WidthSpace(20.w),
                        Expanded(
                          child: ButtonApp(
                            text: "تأكيد",
                            backGround: AppColors.primary,
                            textColor: Colors.white,
                            onTap: () {
                              cubit.updateBookingStatus(id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                hideNavBar: true,
              );
            },
          ),
        );
      },
    );
  }
}
