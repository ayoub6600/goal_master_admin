import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/format_to_hour.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';

class BuildFacilityRow extends StatelessWidget {
  const BuildFacilityRow({super.key, required this.booking});
  final BookingDetails booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Assets.imagesPngImageProfile,
          label: '(${booking.cmnCustomerId})',
          value: 'رقم العميل',
        ),
        HeightSpace(6.h),
        _buildInfoRow(
          icon: Assets.imagesPngImageCalendar,
          label: '',
          value: formatDate(booking.date.toString()),
        ),
        HeightSpace(6.h),
        _buildInfoRow(
          icon: Assets.imagesPngImageClock,
          label: '',
          value: '${formatToHour(booking.startTime)} ',
        ),
        HeightSpace(6.h),
        _buildInfoRow(
          icon: Assets.imagesPngImageClock,
          label: '',
          value: ' ${formatToHour(booking.endTime)}',
        ),
        HeightSpace(6.h),
        _buildInfoRow(
          icon: Assets.imagesPngImageAlbums,
          label: '',
          value: ' ${booking.service}',
        ),
        HeightSpace(6.h),
        _buildInfoRow(
          icon: Assets.imagesPngImageWallet2,
          label: " (${booking.paymentName})",
          value: "${booking.serviceAmount} " "دينار",
        ),
        HeightSpace(6.h),
        _buildInfoRow(
          icon: Assets.imagesPngImageWallet2,
          label: " (${booking.paymentType})",
          value: "${booking.paidAmount} " "دينار",
        ),
        //partially_paid مدفوعة جزئيا
        //paid مدفوع
        //pending  غير مدفوع
        //
      ],
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          icon,
          width: 20.w,
          color: AppColors.primary,
        ),
        WidthSpace(8.w),
        Expanded(
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  text: '$label ',
                  style: AppTextStyles.font16Medium
                      .copyWith(color: AppColors.primary),
                  children: [
                    TextSpan(
                      text: value,
                      style: AppTextStyles.font14Medium
                          .copyWith(color: AppColors.fontColor),
                    ),
                  ],
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
