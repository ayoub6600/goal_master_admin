import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo_imp.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/manager_booking_periods_body.dart';

class ManagerBookingPeriodsView extends StatelessWidget {
  const ManagerBookingPeriodsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ManagerSetupCubit(getIt<ManagerSetupRepoImp>())..loadBootstrap(),
      child: const ManagerBookingPeriodsBody(),
    );
  }
}
