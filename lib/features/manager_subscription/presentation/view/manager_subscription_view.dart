import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/manager_subscription/data/repo/manager_subscription_repo_imp.dart';
import 'package:goal_master_admin/features/manager_subscription/presentation/manager/manager_subscription_cubit/manager_subscription_cubit.dart';
import 'package:goal_master_admin/features/manager_subscription/presentation/view/widgets/manager_subscription_body.dart';

class ManagerSubscriptionView extends StatelessWidget {
  const ManagerSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerSubscriptionCubit(
        getIt<ManagerSubscriptionRepoImp>(),
      )..load(),
      child: const ManagerSubscriptionBody(),
    );
  }
}
