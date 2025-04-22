import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_toggle_cubit/booking_toggle_cubit.dart';

import '../../manager/booking_toggle_cubit/booking_toggle_state.dart';

class FavToggleSection extends StatelessWidget {
  const FavToggleSection({super.key, required this.toggleState});

  final FavToggleState toggleState;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.all(4.r),
      decoration: ShapeDecoration(
        color: AppColors.lightWhite3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FavToggleItem(
              title: 'الأطباء',
              onTap: () {
                context.read<FavToggleCubit>().toggle(
                      isDoc: true,
                    );
              },
              isSelected: toggleState is FavDoctors,
              //svgIcon: AppAssets.normalPerson,
            ),
          ),
          Expanded(
            child: FavToggleItem(
              title: 'المقالات',
              onTap: () {
                context.read<FavToggleCubit>().toggle(isDoc: false);
              },
              isSelected: toggleState is FavArticles,
              //   svgIcon: AppAssets.note2,
            ),
          ),
        ],
      ),
    );
  }
}

class FavToggleItem extends StatelessWidget {
  const FavToggleItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    // required this.svgIcon,
  });

  final String title;
  final bool isSelected;
  final Function onTap;
  // final String svgIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: ShapeDecoration(
          color: isSelected ? Colors.white : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          shadows: [
            if (isSelected)
              const BoxShadow(
                color: Color(0x19000000),
                blurRadius: 32,
                offset: Offset(0, 4),
                spreadRadius: 0,
              )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SvgPicture.asset(
            //   svgIcon,
            //   height: 20.h,
            //   width: 20.w,
            //   colorFilter: isSelected
            //       ? null
            //       : const ColorFilter.mode(
            //           AppColors.lightGrey,
            //           BlendMode.srcIn,
            //         ),
            // ),
            SizedBox(
              width: 8.w,
            ),
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? const Color(0xFF090B0E) : AppColors.lightGrey,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
