import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/items_user_detains_view_body.dart';

class ItemsUserDetainsView extends StatelessWidget {
  const ItemsUserDetainsView({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'المعلومات الشخصية',
      allowBack: true,
      child: ItemsUserDetainsViewBody(
        customer: customer,
      ),
    );
  }
}
