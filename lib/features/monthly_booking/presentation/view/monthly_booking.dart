import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_booking_body.dart';

class MonthlyBookingView extends StatelessWidget {
  const MonthlyBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'الحجز الشهري',
      allowBack: true,
      child: MonthlyBookingBody(),
    );
  }
}
