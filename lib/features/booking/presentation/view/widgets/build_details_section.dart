import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_summary_cards.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_title_row.dart';

class BuildDetailsSection extends StatelessWidget {
  const BuildDetailsSection({
    super.key,
    required this.booking,
    this.onEditTime,
    this.onDisputeProposed,
    this.onCustomerBlockChanged,
  });

  final BookingDetails booking;

  /// Null hides the inline "تعديل الموعد" action on the time card.
  final VoidCallback? onEditTime;

  /// Called after the manager submits a no-show dispute proposal, so the
  /// screen can reload the booking and pick up the fresh dispute state.
  final VoidCallback? onDisputeProposed;

  /// Called after a block/unblock is recorded, so the screen can reload the
  /// booking and pick up the fresh block state.
  final VoidCallback? onCustomerBlockChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          BuildTitleRow(
            booking: booking,
          ),
          HeightSpace(8.h),
          Row(
            children: [
              Text(
                "رقم الحجز :",
                style: AppTextStyles.font14Medium.copyWith(
                  color: AppColors.fontColor,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Color(0xffDADEE3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  " #${booking.id}",
                  style: AppTextStyles.font16Bold.copyWith(
                    color: AppColors.obsidianBlack,
                  ),
                ),
              ),
            ],
          ),
          HeightSpace(18.h),
          BookingTimeCard(booking: booking, onEditTime: onEditTime),
          HeightSpace(14.h),
          BookingCustomerCard(booking: booking, onChanged: onCustomerBlockChanged),
          HeightSpace(14.h),
          BookingPaymentCard(booking: booking, onProposed: onDisputeProposed),
        ],
      ),
    );
  }
}
