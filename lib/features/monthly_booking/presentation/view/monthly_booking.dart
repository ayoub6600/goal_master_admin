import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/error_widgets.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_booking_body.dart';

class MonthlyBookingView extends StatelessWidget {
  const MonthlyBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    final canUseMonthlyBookings = SharedPreferenceUtil.getBool(
      PrefKey.subscriptionAllowMonthlyBookings,
      defValue: true,
    );

    return PageWrapper(
      title: 'الحجز الشهري',
      allowBack: true,
      child: canUseMonthlyBookings
          ? MonthlyBookingBody()
          : const AppErrorView(
              title: 'الحجز الشهري مقفل',
              message: 'الباقة الحالية لا تسمح بإدارة الحجوزات الشهرية.',
              icon: Icons.lock_outline,
            ),
    );
  }
}
