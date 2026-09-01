import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_facility_row%20copy.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_location_row.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_title_row.dart';

class BuildDetailsSection extends StatelessWidget {
  const BuildDetailsSection({
    super.key,
    required this.booking,
  });
  final BookingDetails booking;

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
          HeightSpace(12.h),
          Row(
            children: [
              Text(
                "رقم الحجز :",
                style: AppTextStyles.font16Bold.copyWith(
                  color: AppColors.fontColor,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Color(0xffDADEE3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  " #${booking.id}",
                  style: AppTextStyles.font24Bold.copyWith(
                    color: AppColors.obsidianBlack,
                  ),
                ),
              ),
            ],
          ),
          HeightSpace(12.h),
          BuildLocationRow(
            booking: booking,
          ),
          HeightSpace(30.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "تفاصيل الحجز",
                style: AppTextStyles.font16Bold.copyWith(
                  color: AppColors.fontColor,
                ),
              ),
              HeightSpace(8.h),
              BuildFacilityRow(
                booking: booking,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
