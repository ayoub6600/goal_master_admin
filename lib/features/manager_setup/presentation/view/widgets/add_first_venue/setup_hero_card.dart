import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_stage.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// Header of the venue-setup screen: trial badge, where the manager stands,
/// and a tracker of the three stages.
///
/// This replaced a paragraph that spelled the three stages out in prose and
/// then repeated the wallet balance shown in the card right below it. The
/// tracker says the same thing in a glance and stays accurate on its own.
class SetupHeroCard extends StatelessWidget {
  const SetupHeroCard({super.key, required this.setup});

  final SetupStatus? setup;

  @override
  Widget build(BuildContext context) {
    final isReady = setup?.canStartBooking == true;
    final nextStep = setup?.nextStepLabel ?? 'إعداد بيانات شركة الملاعب';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [SetupColors.heroLight, SetupColors.heroDark],
        ),
        boxShadow: [
          BoxShadow(
            color: SetupColors.heroDark.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrialBadge(),
          HeightSpace(14.h),
          Text(
            isReady ? 'ملعبك جاهز لاستقبال الحجوزات' : 'لنُجهّز ملعبك للحجز',
            style: AppTextStyles.font20Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(6.h),
          Text(
            isReady
                ? 'كل المراحل مكتملة. عدّل أي بيانات من البطاقات بالأسفل.'
                : 'الخطوة التالية: $nextStep',
            style: AppTextStyles.font14Medium.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.5,
            ),
          ),
          HeightSpace(20.h),
          SetupStageTracker(setup: setup),
        ],
      ),
    );
  }
}

class _TrialBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 14.sp,
            color: AppColors.primaryBlueLight,
          ),
          WidthSpace(6.w),
          Text(
            'تجربة مجانية 30 يوم',
            style: AppTextStyles.font12Bold.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Three numbered nodes joined by connectors, one per setup stage.
class SetupStageTracker extends StatelessWidget {
  const SetupStageTracker({super.key, required this.setup});

  final SetupStatus? setup;

  @override
  Widget build(BuildContext context) {
    final stages = SetupStage.of(setup);
    final currentIndex = SetupStage.currentIndexOf(stages);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < stages.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2.h,
                // Sits level with the middle of the circles, which the labels
                // hang below.
                margin: EdgeInsets.only(top: 13.h, left: 2.w, right: 2.w),
                decoration: BoxDecoration(
                  color: stages[index - 1].done
                      ? AppColors.primaryBlueLight.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
          _StageNode(
            number: index + 1,
            stage: stages[index],
            isCurrent: index == currentIndex,
          ),
        ],
      ],
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.number,
    required this.stage,
    required this.isCurrent,
  });

  final int number;
  final SetupStage stage;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Widget inner;

    if (stage.done) {
      fill = AppColors.primaryBlueLight;
      border = AppColors.primaryBlueLight;
      inner = Icon(
        Icons.check_rounded,
        size: 16.sp,
        color: SetupColors.heroDark,
      );
    } else if (isCurrent) {
      fill = Colors.white.withValues(alpha: 0.16);
      border = Colors.white;
      inner = Text(
        '$number',
        style: AppTextStyles.font12Bold.copyWith(color: Colors.white),
      );
    } else {
      fill = Colors.transparent;
      border = Colors.white.withValues(alpha: 0.28);
      inner = Text(
        '$number',
        style: AppTextStyles.font12Bold.copyWith(
          color: Colors.white.withValues(alpha: 0.45),
        ),
      );
    }

    return SizedBox(
      width: 76.w,
      child: Column(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 1.6),
            ),
            child: inner,
          ),
          HeightSpace(8.h),
          Text(
            stage.label,
            textAlign: TextAlign.center,
            style: AppTextStyles.font12Medium.copyWith(
              color: stage.done || isCurrent
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
