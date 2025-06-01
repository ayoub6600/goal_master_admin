import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:intl/intl.dart';

class ItemsNotification extends StatelessWidget {
  const ItemsNotification({
    super.key,
    required this.notification,
    required this.isRead,
  });

  final NotificationItem notification;
  final bool isRead;

  String getFormattedDate(String isoDate) {
    final dateTime = DateTime.tryParse(isoDate);
    if (dateTime == null) return '';
    return DateFormat('yyyy-MM-dd – HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final message = notification.data.message;
    final createdAt =
        getFormattedDate(notification.createdAt.toIso8601String());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[100] : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              isRead ? Colors.transparent : AppColors.primary.withOpacity(0.1),
          width: 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.grey[200]
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              Assets.imagesPngImageNotification,
              height: 24.h,
              width: 24.w,
              color: isRead ? Colors.grey[500] : AppColors.primary,
            ),
          ),
          WidthSpace(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.font14SemiBold.copyWith(
                    color: isRead ? Colors.grey[600] : AppColors.black,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                HeightSpace(6.h),
                Text(
                  createdAt,
                  style: AppTextStyles.font12Regular.copyWith(
                    color: isRead ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
