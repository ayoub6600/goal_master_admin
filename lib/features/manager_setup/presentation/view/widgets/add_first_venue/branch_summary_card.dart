import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// Read-only summary of the saved company details, with a way back into
/// editing them.
class BranchSummaryCard extends StatelessWidget {
  const BranchSummaryCard({
    super.key,
    required this.branch,
    required this.onEdit,
  });

  final ExistingBranch branch;

  /// Null while the form below is already open for editing.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (label: 'اسم الشركة', value: branch.name),
      (label: 'المنطقة', value: branch.zoneName),
      (label: 'الهاتف', value: branch.phone),
      (label: 'البريد', value: branch.email),
      (label: 'العنوان', value: branch.address),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: SetupColors.cardBorder),
        boxShadow: SetupColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'بيانات شركة الملاعب',
                  style: AppTextStyles.font16Bold,
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    minimumSize: Size(0, 32.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'تعديل',
                    style: AppTextStyles.font14Bold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          HeightSpace(10.h),
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              Divider(height: 18.h, color: SetupColors.cardBorder),
            _SummaryRow(label: rows[index].label, value: rows[index].value),
          ],
        ],
      ),
    );
  }
}

/// One label/value pair.
///
/// The label sits in a fixed column so every value lines up, and an empty
/// value reads as "لم يُضف" rather than leaving the label dangling with
/// nothing after the colon.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.trim().isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82.w,
          child: Text(
            label,
            style: AppTextStyles.font14Medium.copyWith(
              color: SetupColors.secondaryText,
            ),
          ),
        ),
        WidthSpace(8.w),
        Expanded(
          child: Text(
            isEmpty ? 'لم يُضف' : value,
            style: isEmpty
                ? AppTextStyles.font14Regular.copyWith(
                    color: SetupColors.muted,
                    fontStyle: FontStyle.italic,
                  )
                : AppTextStyles.font14Bold.copyWith(color: AppColors.uiBlack),
          ),
        ),
      ],
    );
  }
}
