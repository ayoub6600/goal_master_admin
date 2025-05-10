import 'package:flutter/material.dart';

import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_list.dart';

class BookingViewBody extends StatelessWidget {
  const BookingViewBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeightSpace(16),
        // FavToggleSection(
        //   toggleState: state,
        // ),
        Expanded(child: BookingList()),
      ],
    );
  }
}
