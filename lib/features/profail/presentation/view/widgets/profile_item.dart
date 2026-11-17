import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';

class ProfileItem extends StatelessWidget {
  const ProfileItem({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.child,
    this.badge = 0,
  });
  final String title;
  final String icon;
  final Function()? onTap;
  final Widget? child;

  /// A red count before the arrow (unread replies); hidden at 0.
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              fit: BoxFit.cover,
              color: AppColors.primary,
            ),
            WidthSpace(16.w),
            Expanded(
              child: Text(
                title,
                //  textDirection: TextDirection.rtl,
                style: AppTextStyles.font16Bold.copyWith(
                  color: AppColors.fontColor,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                margin: EdgeInsetsDirectional.only(end: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: AppTextStyles.font12Bold.copyWith(color: Colors.white),
                ),
              ),
            child != null
                ? SizedBox()
                : Image.asset(
                    Assets.imagesPngImageArrowLeft,
                    fit: BoxFit.cover,
                  ),
          ],
        ),
      ),
    );
  }
}
