import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/features/manager_wallet/data/model/manager_wallet_response.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo_imp.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_cubit/manager_wallet_cubit.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_cubit/manager_wallet_state.dart';

class ManagerPaymentSettingsView extends StatelessWidget {
  const ManagerPaymentSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerWalletCubit(getIt<ManagerWalletRepoImp>())..load(),
      child: const _ManagerPaymentSettingsBody(),
    );
  }
}

class _ManagerPaymentSettingsBody extends StatelessWidget {
  const _ManagerPaymentSettingsBody();

  Future<void> _toggleLocalPayment(
    BuildContext context,
    bool enabled,
  ) async {
    final result =
        await getIt<ManagerWalletRepoImp>().updateLocalPaymentSetting(enabled);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.errMessage)),
      ),
      (message) async {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        await context.read<ManagerWalletCubit>().load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'إعدادات الدفع',
      child: BlocBuilder<ManagerWalletCubit, ManagerWalletState>(
        builder: (context, state) {
          if (state is ManagerWalletLoading || state is ManagerWalletInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ManagerWalletFailure) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.read<ManagerWalletCubit>().load(),
                child: const Text('إعادة المحاولة'),
              ),
            );
          }

          final data = (state as ManagerWalletLoaded).data;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ManagerLocalPaymentSettingsCard(
                data: data,
                onChanged: (value) => _toggleLocalPayment(context, value),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ManagerLocalPaymentSettingsCard extends StatelessWidget {
  const _ManagerLocalPaymentSettingsCard({
    required this.data,
    required this.onChanged,
  });

  final WalletData data;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final localPayment = data.localPayment;
    final canEnable = localPayment.subscriptionAllowsLocalPayment;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffD7E8D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الدفع عند الوصول',
            style: AppTextStyles.font18Bold,
          ),
          HeightSpace(8.h),
          Text(
            canEnable
                ? 'إذا فعّلت هذا الخيار، يستطيع الزبون إرسال طلب الحجز بدون دفع فوري، ويبقى الطلب بانتظار موافقتك.'
                : 'هذه الميزة مقفلة لأن الباقة الحالية لا تسمح بها.',
            style: AppTextStyles.font14Regular.copyWith(height: 1.5),
          ),
          HeightSpace(12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  localPayment.enabledForBranch
                      ? 'الحالة الحالية: مفعّل'
                      : 'الحالة الحالية: غير مفعّل',
                  style: AppTextStyles.font16Medium.copyWith(
                    color: localPayment.enabledForBranch
                        ? AppColors.primary
                        : Colors.redAccent,
                  ),
                ),
              ),
              Switch(
                value: canEnable && localPayment.enabledForBranch,
                onChanged: canEnable ? onChanged : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
