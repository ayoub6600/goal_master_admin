import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';
import 'package:image_picker/image_picker.dart';

/// Logo chooser for the company.
class VenueLogoPicker extends StatelessWidget {
  const VenueLogoPicker({
    super.key,
    required this.selectedImage,
    required this.existingImageUrl,
    required this.onPick,
  });

  final XFile? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onPick;

  bool get _hasExisting =>
      existingImageUrl != null && existingImageUrl!.isNotEmpty;

  bool get _hasAnyImage => selectedImage != null || _hasExisting;

  @override
  Widget build(BuildContext context) {
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
                child: Text('شعار الشركة', style: AppTextStyles.font16Bold),
              ),
              if (_hasAnyImage)
                TextButton.icon(
                  onPressed: onPick,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    minimumSize: Size(0, 32.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    size: 17.sp,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'تغيير',
                    style: AppTextStyles.font14Bold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          HeightSpace(12.h),
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 170.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: SetupColors.fieldFill,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: _hasAnyImage
                      ? SetupColors.fieldBorder
                      : AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : _hasExisting
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Image.network(
                            existingImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const _LogoPlaceholder(),
                          ),
                        )
                      : const _LogoPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 28.sp,
            color: AppColors.primary,
          ),
        ),
        HeightSpace(10.h),
        Text(
          'اضغط لاختيار شعار الشركة',
          style: AppTextStyles.font14Bold.copyWith(color: AppColors.primary),
        ),
        HeightSpace(4.h),
        Text(
          'صورة مربعة تظهر للزبائن',
          style: AppTextStyles.font12Regular.copyWith(
            color: SetupColors.muted,
          ),
        ),
      ],
    );
  }
}
