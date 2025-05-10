import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_view_body%20copy.dart';

class BookingView extends StatelessWidget {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
        title: 'الحجز', allowBack: false, child: BookingViewBody());
  }
}
