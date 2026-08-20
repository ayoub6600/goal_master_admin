import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/cancel_booking_cubit/cancel_booking_cubit.dart';

class CancelBookingButton extends StatelessWidget {
  const CancelBookingButton({
    super.key,
    required this.id,
    this.isApprovalFlow = false,
  });
  final int id;
  final bool isApprovalFlow;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CancelBookingCubit, CancelBookingState>(
      listener: (context, state) {
        if (state is CancelBookingSuccess) {
          CustomSuccessToast(toastText: state.message);
          context.read<BookingDetailsCubit>().getBookingInfo();
          Navigator.pop(context);
        } else if (state is CancelBookingFailure) {
          CustomFailureToastWidget(toastText: state.message);
        }
      },
      builder: (context, state) {
        return Expanded(
          child: ButtonApp(
            text: state is CancelBookingLoading
                ? (isApprovalFlow ? "جاري رفض الحجز" : "جاري الغاء الحجز")
                : (isApprovalFlow ? "رفض الحجز" : "الغاء الحجز"),
            textColor: Colors.white,
            backGround: AppColors.redcolor,
            onTap: () {
              baseBottomSheet(
                title: isApprovalFlow ? "رفض الحجز" : "الغاء الحجز",
                context: context,
                child: Column(
                  children: [
                    Text(
                      isApprovalFlow
                          ? "هل أنت متأكد من رفض هذا الحجز؟"
                          : "هل انت متأكد من الغاء الحجز؟",
                    ),
                    HeightSpace(20.h),
                    Row(
                      children: [
                        Expanded(
                            child: ButtonApp(
                                backGround: AppColors.grey,
                                text: isApprovalFlow ? "رجوع" : "الغاء",
                                onTap: () {
                                  Navigator.pop(context);
                                })),
                        WidthSpace(20.w),
                        Expanded(
                          child: ButtonApp(
                            text: isApprovalFlow ? "رفض الحجز" : "تأكيد",
                            backGround: AppColors.redcolor,
                            textColor: Colors.white,
                            onTap: () {
                              context
                                  .read<CancelBookingCubit>()
                                  .cancelBooking(id);
                            },
                          ),
                        )
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
