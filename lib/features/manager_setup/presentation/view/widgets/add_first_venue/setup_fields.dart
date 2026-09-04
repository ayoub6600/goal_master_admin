import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// A labelled text input used throughout the venue-setup form.
class SetupTextField extends StatelessWidget {
  const SetupTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  /// Explanatory line under the field. Lives inside the field widget so the
  /// help sits tight against the input it belongs to instead of floating as a
  /// loose paragraph in the form.
  final String? helper;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: const BorderSide(color: SetupColors.fieldBorder),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTextStyles.font14Medium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.font14Regular.copyWith(
              color: SetupColors.muted,
            ),
            filled: true,
            fillColor: SetupColors.fieldFill,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
        if (helper != null) ...[
          HeightSpace(6.h),
          Text(
            helper!,
            style: AppTextStyles.font12Regular.copyWith(
              color: SetupColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// A labelled row that opens a picker sheet and shows the current choice.
class SetupSelectField extends StatelessWidget {
  const SetupSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String? value;

  /// Shown when nothing is chosen yet. Passed in per field — the zone picker
  /// and the category picker are not asking for the same thing.
  final String placeholder;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: SetupColors.fieldFill,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: SetupColors.fieldBorder),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20.sp),
                  WidthSpace(10.w),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: AppTextStyles.font14Medium.copyWith(
                      color: hasValue
                          ? AppColors.uiBlack
                          : SetupColors.muted,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SetupColors.muted,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom-sheet list used by both the zone picker and the category picker.
Future<T?> showSetupOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) labelOf,
  required bool Function(T option) isSelected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeightSpace(12.h),
            Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: SetupColors.fieldBorder,
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
            HeightSpace(14.h),
            Text(title, style: AppTextStyles.font18Bold),
            HeightSpace(6.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: SetupColors.cardBorder,
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = isSelected(option);

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    title: Text(
                      labelOf(option),
                      style: selected
                          ? AppTextStyles.font16Bold
                              .copyWith(color: AppColors.primary)
                          : AppTextStyles.font16Medium,
                    ),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
