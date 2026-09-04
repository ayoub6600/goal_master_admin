import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// A titled card for one stage of the setup flow.
///
/// The numbered badge ties the card back to the same number in the hero
/// tracker, so "step 2" on the tracker and the "الفئة والخدمات" card are
/// visibly the same thing.
class SetupSectionCard extends StatelessWidget {
  const SetupSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.step,
    this.isDone = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final int? step;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDone ? SetupColors.doneBorder : SetupColors.cardBorder,
        ),
        boxShadow: SetupColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step != null) ...[
                StepBadge(step: step!, isDone: isDone),
                WidthSpace(12.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title, style: AppTextStyles.font18Bold),
                        ),
                        if (isDone) ...[
                          WidthSpace(8.w),
                          const DoneChip(),
                        ],
                      ],
                    ),
                    HeightSpace(6.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.font12Medium.copyWith(
                        color: SetupColors.muted,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          HeightSpace(18.h),
          child,
        ],
      ),
    );
  }
}

/// Square number badge shown at the head of a section card.
class StepBadge extends StatelessWidget {
  const StepBadge({super.key, required this.step, required this.isDone});

  final int step;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: isDone
          ? Icon(Icons.check_rounded, size: 19.sp, color: Colors.white)
          : Text(
              '$step',
              style: AppTextStyles.font16Bold.copyWith(
                color: AppColors.primary,
              ),
            ),
    );
  }
}

/// Small "مكتمل" pill next to a finished section's title.
class DoneChip extends StatelessWidget {
  const DoneChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xffEEF8F0),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Text(
        'مكتمل',
        style: AppTextStyles.font10Bold.copyWith(color: AppColors.primary),
      ),
    );
  }
}
