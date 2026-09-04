import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_section_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// Stage 3 — a doorway into the separate booking-periods screen.
class BookingPeriodsCard extends StatelessWidget {
  const BookingPeriodsCard({
    super.key,
    required this.isDone,
    required this.onOpen,
  });

  final bool isDone;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SetupSectionCard(
      step: 3,
      isDone: isDone,
      title: 'فترات الحجز',
      subtitle: 'ساعات الحجز المسائي والحجز بعد منتصف الليل، '
          'تُدار من شاشة مستقلة.',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: SetupColors.fieldFill,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: SetupColors.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              WidthSpace(12.w),
              Expanded(
                child: Text(
                  'فتح إدارة فترات الحجز',
                  style: AppTextStyles.font14Bold,
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: SetupColors.muted,
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
