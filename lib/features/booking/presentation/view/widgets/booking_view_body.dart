import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_toggle_cubit/booking_toggle_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_toggle_cubit/booking_toggle_state.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/fav_toggle_section.dart';

class FavViewBody extends StatelessWidget {
  const FavViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FavToggleCubit, FavToggleState>(
      listener: (context, state) {
        if (state is FavDoctors) {
          //   context.read<DoctorsCubit>().refreshDoctors();
        } else if (state is FavArticles) {
          // context.read<ArticlesCubit>().refreshArticles();
        }
      },
      builder: (context, toggleState) => Padding(
        padding: EdgeInsets.all(8.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FavToggleSection(toggleState: toggleState),
            HeightSpace(16.h),
            if (toggleState is FavDoctors)
              const Expanded(child: Text("Doctors List Section")),
            if (toggleState is FavArticles)
              const Expanded(child: Text("Articles List Section")),
            HeightSpace(70.h),
          ],
        ),
      ),
    );
  }
}
