// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';

class Dot extends StatelessWidget {
  const Dot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.w,
      height: 4.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.r),
        color: AppColors.mainGrey,
      ),
    );
  }
}
