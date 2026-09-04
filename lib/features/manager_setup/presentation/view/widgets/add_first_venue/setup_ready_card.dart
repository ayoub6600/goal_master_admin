import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// Shown once every stage is finished and the venue can take bookings.
class SetupReadyCard extends StatelessWidget {
  const SetupReadyCard({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xffEEF8F0),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xffCBE5D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              WidthSpace(12.w),
              Expanded(
                child: Text(
                  'الحساب جاهز للحجز',
                  style: AppTextStyles.font18Bold,
                ),
              ),
            ],
          ),
          HeightSpace(12.h),
          Text(
            'تم تجهيز الشركة والفئة والخدمات وربطها بفترات الحجز. يمكنك الآن الرجوع '
            'للشاشة الرئيسية وبدء استقبال الحجوزات.',
            style: AppTextStyles.font14Medium.copyWith(
              color: SetupColors.secondaryText,
              height: 1.6,
            ),
          ),
          HeightSpace(16.h),
          ButtonApp(text: 'الرجوع للرئيسية', onTap: onGoHome),
        ],
      ),
    );
  }
}
