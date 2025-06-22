import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';

Future<T?> baseBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  required bool hideNavBar,
  bool showDragHandle = true,
  String? title,
  bool showCloseButton = true,
}) async {
  void handleNavBar(bool isVisible) {
    if (hideNavBar) {
      //  isVisible ? navBarCubit.showNavBar() : navBarCubit.hideNavBar();
    }
  }

  handleNavBar(false);

  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    builder: (context) {
      return PopScope(
        onPopInvokedWithResult: (_, __) => handleNavBar(true),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: showDragHandle ? 8 : 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDragHandle)
                  Center(
                    child: Container(
                      height: 4.h,
                      width: 130.w,
                      margin: EdgeInsets.only(bottom: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.uiBlack,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.font18Medium.copyWith(
                            color: AppColors.dark3,
                          ),
                        ),
                      ],
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(() => handleNavBar(true));
}
