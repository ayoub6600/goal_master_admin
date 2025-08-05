import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class MonthlyBookingLoading extends StatelessWidget {
  const MonthlyBookingLoading({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (_, __) => Shimmer(
          duration: const Duration(seconds: 2),
          interval: const Duration(seconds: 0),
          color: Colors.white,
          colorOpacity: 0,
          enabled: true,
          direction: const ShimmerDirection.fromLTRB(),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: Colors.grey.shade300,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16.h, width: 120.w, color: Colors.white),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(width: 40.w, height: 40.w, color: Colors.white),
                    SizedBox(width: 8.w),
                    Container(height: 14.h, width: 200.w, color: Colors.white),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                    height: 12.h, width: double.infinity, color: Colors.white),
                SizedBox(height: 8.h),
                Container(height: 12.h, width: 180.w, color: Colors.white),
                SizedBox(height: 8.h),
                Container(
                    height: 12.h, width: double.infinity, color: Colors.white),
                SizedBox(height: 8.h),
                Container(height: 12.h, width: 160.w, color: Colors.white),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(height: 32.h, width: 80.w, color: Colors.white),
                    SizedBox(width: 8.w),
                    Container(height: 32.h, width: 80.w, color: Colors.white),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                    height: 40.h, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
