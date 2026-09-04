import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/manager_service_draft.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_fields.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// One pitch being added or edited inside the catalog form.
///
/// A pitch is a name and a price. WHEN it can be booked is decided once, on
/// «فترات الحجز», against the venue's actual hours — asking it again here in
/// the old band vocabulary meant the same fact had two owners that could
/// disagree.
class ServiceDraftCard extends StatelessWidget {
  const ServiceDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  final int index;
  final ManagerServiceDraft draft;

  /// Null when this is the only draft left — the form always keeps one.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffFBFCFB),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.font12Bold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              WidthSpace(10.w),
              Expanded(
                child: Text('الخدمة', style: AppTextStyles.font16Bold),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'حذف الخدمة',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                    size: 21.sp,
                  ),
                ),
            ],
          ),
          HeightSpace(12.h),
          SetupTextField(
            controller: draft.titleController,
            label: 'اسم الخدمة أو الملعب',
            hint: 'مثال: سداسي 1 أو ملعب سباعي',
          ),
          HeightSpace(12.h),
          SetupTextField(
            controller: draft.priceController,
            label: 'السعر بالدينار',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          HeightSpace(12.h),
          SetupTextField(
            controller: draft.remarksController,
            label: 'وصف مختصر',
            hint: 'اختياري',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

/// The time channels the venue currently runs, shown for context above the
/// catalog form.
class EmployeeChannelsPreview extends StatelessWidget {
  const EmployeeChannelsPreview({super.key, required this.channelNames});

  final List<String> channelNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: SetupColors.tintedSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: SetupColors.doneBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 17.sp,
                color: AppColors.primary,
              ),
              WidthSpace(8.w),
              Text('القنوات الزمنية الحالية', style: AppTextStyles.font14Bold),
            ],
          ),
          HeightSpace(10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final name in channelNames)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99.r),
                    border: Border.all(color: SetupColors.doneBorder),
                  ),
                  child: Text(
                    name,
                    style: AppTextStyles.font12Medium.copyWith(
                      color: SetupColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
