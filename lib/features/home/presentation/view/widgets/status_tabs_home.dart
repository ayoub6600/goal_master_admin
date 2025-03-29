import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/items_home_view_list.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

class StatusTabsHome extends StatelessWidget {
  final List<String> statuses = [
    "المكتمل",
    "الموافق عليه",
    "الملغي",
    "الانتظار"
  ];

  StatusTabsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // height: 120,
      child: DefaultTabController(
        length: statuses.length,
        child: Column(
          children: [
            TabBar(
              tabs: statuses.map((status) => Tab(text: status)).toList(),
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.black54,
              indicator: MaterialIndicator(
                height: 4,
                color: AppColors.primary,
                topLeftRadius: 8,
                topRightRadius: 8,
                bottomLeftRadius: 0,
                bottomRightRadius: 0,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                children: statuses
                    .map((status) => ItemsHomeViewList(title: status))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
