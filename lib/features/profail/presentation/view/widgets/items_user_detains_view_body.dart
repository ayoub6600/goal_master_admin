import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_list.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/items_user_call.dart';

class ItemsUserDetainsViewBody extends StatelessWidget {
  const ItemsUserDetainsViewBody({super.key, required this.customer});
  final Customer customer;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemsUserCall(customer: customer),
        HeightSpace(16.h),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "الحجوزات",
            style: AppTextStyles.font16Bold.copyWith(color: Colors.black),
          ),
        ),
        Expanded(child: BookingList()),
      ],
    );
  }
}
