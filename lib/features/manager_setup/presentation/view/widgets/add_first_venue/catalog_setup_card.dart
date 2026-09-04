import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/manager_service_draft.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/service_draft_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_fields.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_section_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// Stage 2 — the venue's category and the pitches under it.
class CatalogSetupCard extends StatelessWidget {
  const CatalogSetupCard({
    super.key,
    required this.selectedCategoryName,
    required this.channelNames,
    required this.drafts,
    required this.isSubmitting,
    required this.isDone,
    required this.onSelectCategory,
    required this.onAddService,
    required this.onRemoveService,
    required this.onSubmit,
  });

  final String? selectedCategoryName;
  final List<String> channelNames;
  final List<ManagerServiceDraft> drafts;
  final bool isSubmitting;
  final bool isDone;
  final VoidCallback onSelectCategory;
  final VoidCallback onAddService;
  final void Function(int index) onRemoveService;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SetupSectionCard(
      step: 2,
      isDone: isDone,
      title: 'الفئة والخدمات',
      subtitle: 'اختر فئة الملعب، ثم أضف كل ملعب أو خدمة بسعره. '
          'الفئات تُدار من لوحة الإدارة.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (channelNames.isNotEmpty) ...[
            EmployeeChannelsPreview(channelNames: channelNames),
            HeightSpace(16.h),
          ],
          SetupSelectField(
            label: 'فئة الملعب',
            value: selectedCategoryName,
            placeholder: 'اختر فئة الملعب',
            icon: Icons.category_outlined,
            onTap: onSelectCategory,
          ),
          HeightSpace(20.h),
          Row(
            children: [
              Text('الخدمات أو الملاعب', style: AppTextStyles.font16Bold),
              WidthSpace(8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: SetupColors.fieldFill,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: SetupColors.fieldBorder),
                ),
                child: Text(
                  '${drafts.length}',
                  style: AppTextStyles.font12Bold.copyWith(
                    color: SetupColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          HeightSpace(12.h),
          for (var index = 0; index < drafts.length; index++)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ServiceDraftCard(
                index: index,
                draft: drafts[index],
                onRemove:
                    drafts.length > 1 ? () => onRemoveService(index) : null,
              ),
            ),
          _AddServiceButton(onTap: onAddService),
          HeightSpace(20.h),
          ButtonApp(
            text: isSubmitting ? 'جارٍ الحفظ...' : 'حفظ الفئة والخدمات',
            backGround: isSubmitting ? SetupColors.muted : null,
            onTap: isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _AddServiceButton extends StatelessWidget {
  const _AddServiceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 19.sp,
              color: AppColors.primary,
            ),
            WidthSpace(8.w),
            Text(
              'إضافة خدمة أخرى',
              style: AppTextStyles.font14Bold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
