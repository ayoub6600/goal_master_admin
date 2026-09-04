import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_fields.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_section_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// Stage 1 — the company's name, area, contact details and map pin.
class BranchFormCard extends StatelessWidget {
  const BranchFormCard({
    super.key,
    required this.branchNameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.selectedZoneName,
    required this.latitude,
    required this.longitude,
    required this.isSubmitting,
    required this.isDone,
    required this.onSelectZone,
    required this.onPickLocation,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController branchNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final String? selectedZoneName;
  final String latitude;
  final String longitude;
  final bool isSubmitting;
  final bool isDone;
  final VoidCallback onSelectZone;
  final VoidCallback onPickLocation;
  final VoidCallback onSubmit;

  /// Null on first-time setup, where there is nothing to cancel back to.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SetupSectionCard(
      step: 1,
      isDone: isDone,
      title: 'بيانات الشركة',
      subtitle: 'اسم الشركة المالكة للملاعب، منطقتها، وبيانات التواصل.',
      child: Column(
        children: [
          SetupTextField(
            controller: branchNameController,
            label: 'اسم الشركة المالكة للملاعب',
            hint: 'مثال: ملاعب الجزيرة',
          ),
          HeightSpace(14.h),
          SetupSelectField(
            label: 'المنطقة',
            value: selectedZoneName,
            placeholder: 'اختر المنطقة',
            icon: Icons.location_city_outlined,
            onTap: onSelectZone,
          ),
          HeightSpace(14.h),
          SetupTextField(
            controller: phoneController,
            label: 'رقم الهاتف',
            hint: '09XXXXXXXX',
            keyboardType: TextInputType.phone,
          ),
          HeightSpace(14.h),
          SetupTextField(
            controller: emailController,
            label: 'البريد الإلكتروني (اختياري)',
            keyboardType: TextInputType.emailAddress,
            helper: 'بريد التواصل الخاص بالشركة، ويمكن أن يختلف عن بريد دخولك. '
                'اتركه فارغًا إن لم يكن لديك بريد مختلف.',
          ),
          HeightSpace(14.h),
          SetupTextField(
            controller: addressController,
            label: 'العنوان',
            hint: 'اسم الشارع أو أقرب معلم',
            maxLines: 2,
          ),
          HeightSpace(14.h),
          _LocationRow(
            latitude: latitude,
            longitude: longitude,
            onTap: onPickLocation,
          ),
          HeightSpace(20.h),
          ButtonApp(
            text: isSubmitting ? 'جارٍ الحفظ...' : 'حفظ بيانات الشركة',
            backGround: isSubmitting ? SetupColors.muted : null,
            onTap: isSubmitting ? null : onSubmit,
          ),
          if (onCancel != null) ...[
            HeightSpace(6.h),
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
              child: Text(
                'إلغاء',
                style: AppTextStyles.font14Bold.copyWith(
                  color: SetupColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable row showing whether the venue's map pin has been dropped yet.
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final String latitude;
  final String longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude.isNotEmpty && longitude.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('موقع الملعب', style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: hasPin
                  ? SetupColors.tintedSurface
                  : SetupColors.fieldFill,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: hasPin
                    ? SetupColors.doneBorder
                    : SetupColors.fieldBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasPin ? Icons.place_rounded : Icons.map_outlined,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                WidthSpace(10.w),
                Expanded(
                  child: hasPin
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تم تحديد الموقع',
                              style: AppTextStyles.font14Bold.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            HeightSpace(2.h),
                            Text(
                              '$latitude, $longitude',
                              style: AppTextStyles.font12Regular.copyWith(
                                color: SetupColors.secondaryText,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'اضغط لتحديد موقع الملعب على الخريطة',
                          style: AppTextStyles.font14Medium.copyWith(
                            color: SetupColors.muted,
                          ),
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
      ],
    );
  }
}
