import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';

import 'package:goal_master_admin/features/profail/presentation/view/widgets/allowed_amount_view_body.dart';

class AllowedAmountView extends StatelessWidget {
  const AllowedAmountView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
        title: 'القيمة المسموح بها',
        allowBack: true,
        child: AllowedAmountViewBody());
  }
}
