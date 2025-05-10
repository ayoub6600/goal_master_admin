import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/allowed_amount_cubit/allowed_amount_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/allowed_amount_card.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class AllowedAmountViewBody extends StatelessWidget {
  const AllowedAmountViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllowedAmountCubit, AllowedAmountState>(
      builder: (context, state) {
        if (state is AllowedAmountLoaded) {
          return PagedListView<int, AllowedAmountData>(
            pagingController: state.pagingController,
            padding: const EdgeInsets.all(16),
            builderDelegate: PagedChildBuilderDelegate<AllowedAmountData>(
              itemBuilder: (context, item, index) =>
                  AllowedAmountCard(item: item),
              noItemsFoundIndicatorBuilder: (_) =>
                  const Center(child: Text("لا توجد بيانات")),
              firstPageErrorIndicatorBuilder: (_) =>
                  const Center(child: Text("حدث خطأ في تحميل البيانات")),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
