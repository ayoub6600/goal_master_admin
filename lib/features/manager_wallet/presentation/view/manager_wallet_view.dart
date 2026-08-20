import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_wallet/data/model/manager_wallet_response.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo_imp.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_card_cubit/manager_wallet_card_cubit.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_cubit/manager_wallet_cubit.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_cubit/manager_wallet_state.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/view/widgets/manager_top_up_sheet_card.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/view/widgets/manager_top_up_sheet_visa.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/view/widgets/manager_wallet_payment_methods_sheet.dart';

class ManagerWalletView extends StatelessWidget {
  const ManagerWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerWalletCubit(getIt<ManagerWalletRepoImp>())..load(),
      child: const _ManagerWalletBody(),
    );
  }
}

class _ManagerWalletBody extends StatelessWidget {
  const _ManagerWalletBody();

  Future<void> _openTopUp(BuildContext context) async {
    final method = await baseBottomSheet<String>(
      context: context,
      hideNavBar: true,
      title: 'خدمات المحفظة',
      child: const ManagerWalletPaymentMethodsSheet(),
    );

    if (!context.mounted || method == null) return;

    bool? shouldReload;

    if (method == 'visa') {
      shouldReload = await baseBottomSheet<bool>(
        context: context,
        hideNavBar: true,
        title: 'شحن المحفظة',
        child: const ManagerTopUpSheetVisa(),
      );
    } else if (method == 'card') {
      shouldReload = await baseBottomSheet<bool>(
        context: context,
        hideNavBar: true,
        title: 'شحن بالكرت',
        child: BlocProvider(
          create: (_) => ManagerWalletCardCubit(getIt<ManagerWalletRepoImp>()),
          child: const ManagerTopUpSheetCard(),
        ),
      );
    }

    if (shouldReload == true && context.mounted) {
      context.read<ManagerWalletCubit>().load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المحفظة بنجاح')),
      );
    }
  }

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
      title: 'محفظة مدير الملعب',
      child: BlocBuilder<ManagerWalletCubit, ManagerWalletState>(
        builder: (context, state) {
          if (state is ManagerWalletLoading || state is ManagerWalletInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ManagerWalletFailure) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font16Medium,
                    ),
                    HeightSpace(12.h),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ManagerWalletCubit>().load(),
                      child: const Text('إعادة التحميل'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = (state as ManagerWalletLoaded).data;
          final transactionItems =
              data.transactions?.items ?? data.wallet.recentTransactions;

          return RefreshIndicator(
            onRefresh: () => context.read<ManagerWalletCubit>().load(),
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _WalletHeroCard(
                  data: data,
                  onTopUpTap: () => _openTopUp(context),
                ),
                HeightSpace(16.h),
                _ManagerLocalPaymentCard(
                  data: data,
                  onChanged: (value) => _toggleLocalPayment(context, value),
                ),
                HeightSpace(16.h),
                _WalletSummaryRow(data: data.wallet),
                HeightSpace(16.h),
                Text(
                  'آخر الحركات',
                  style: AppTextStyles.font18Bold,
                ),
                HeightSpace(12.h),
                if (transactionItems.isEmpty)
                  _EmptyWalletCard(
                      isTrialActive: data.subscription.isTrialActive)
                else
                  ...transactionItems
                      .map((item) => _WalletTransactionTile(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ManagerLocalPaymentCard extends StatelessWidget {
  const _ManagerLocalPaymentCard({
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
                ? 'فعّل هذه الميزة إذا كنت تريد السماح للزبون بإرسال طلب حجز بدون دفع فوري، على أن توافق عليه أنت لاحقًا.'
                : 'هذه الميزة غير متاحة في الباقة الحالية.',
            style: AppTextStyles.font14Regular.copyWith(height: 1.5),
          ),
          HeightSpace(12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  localPayment.enabledForBranch
                      ? 'مفعّل لهذا الملعب'
                      : 'غير مفعّل لهذا الملعب',
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

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.data,
    required this.onTopUpTap,
  });

  final WalletData data;
  final VoidCallback onTopUpTap;

  @override
  Widget build(BuildContext context) {
    final planName = data.subscription.planName.isEmpty
        ? 'بدون باقة محددة'
        : data.subscription.planName;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          colors: [Color(0xff0F2D1E), Color(0xff1F5234)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرصيد الحالي',
            style: AppTextStyles.font14Medium.copyWith(color: Colors.white70),
          ),
          HeightSpace(8.h),
          Text(
            '${data.wallet.currentBalance.toStringAsFixed(2)} د.ل',
            style: AppTextStyles.font24Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(14.h),
          Text(
            'الباقة الحالية: $planName',
            style: AppTextStyles.font14Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(8.h),
          Text(
            data.subscription.isTrialActive
                ? 'فترة التجربة ما زالت فعالة، لذلك لا يوجد دفع مطلوب الآن. جهزنا المحفظة من الآن حتى تكون جاهزة عند التفعيل التجاري.'
                : 'المحفظة جاهزة. الخطوة التالية لاحقًا ستكون ربط الشحن والدفع المباشر من داخل التطبيق.',
            style: AppTextStyles.font14Regular.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.5,
            ),
          ),
          HeightSpace(16.h),
          ButtonApp(
            text: data.subscription.isTrialActive
                ? 'شحن اختياري للمحفظة'
                : 'شحن المحفظة',
            backGround: Colors.white,
            textColor: AppColors.primary,
            onTap: onTopUpTap,
          ),
        ],
      ),
    );
  }
}

class _WalletSummaryRow extends StatelessWidget {
  const _WalletSummaryRow({required this.data});

  final WalletSummaryData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryMetricCard(
            title: 'عدد الحركات',
            value: '${data.transactionsCount}',
          ),
        ),
        WidthSpace(12.w),
        Expanded(
          child: _SummaryMetricCard(
            title: 'آخر 5 حركات',
            value: '${data.recentTransactions.length}',
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBF6),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffD7E8D3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.font20Bold.copyWith(color: AppColors.primary),
          ),
          HeightSpace(6.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.font12Medium,
          ),
        ],
      ),
    );
  }
}

class _EmptyWalletCard extends StatelessWidget {
  const _EmptyWalletCard({required this.isTrialActive});

  final bool isTrialActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xffFBFCFA),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE2ECDD)),
      ),
      child: Text(
        isTrialActive
            ? 'لا توجد أي حركة مالية بعد. هذا طبيعي لأن الحساب ما زال داخل الفترة التجريبية.'
            : 'لا توجد أي حركة مالية بعد. سنربط الشحن والسداد من داخل التطبيق في الخطوة التالية.',
        textAlign: TextAlign.center,
        style: AppTextStyles.font14Medium.copyWith(height: 1.6),
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({required this.item});

  final WalletTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final amountColor = item.isCredit ? const Color(0xff2E7D32) : Colors.red;
    final title = item.description.isNotEmpty ? item.description : item.type;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE6ECE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: amountColor,
            ),
          ),
          WidthSpace(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'عملية مالية' : title,
                  style: AppTextStyles.font14Bold,
                ),
                if (item.referenceUser != null) ...[
                  HeightSpace(4.h),
                  Text(
                    item.referenceUser!.name.isEmpty
                        ? item.referenceUser!.phoneNumber
                        : '${item.referenceUser!.name} • ${item.referenceUser!.phoneNumber}',
                    style: AppTextStyles.font12Medium.copyWith(
                      color: const Color(0xff6D7580),
                    ),
                  ),
                ],
                HeightSpace(4.h),
                Text(
                  item.createdAt,
                  style: AppTextStyles.font12Medium.copyWith(
                    color: const Color(0xff8C939D),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.isCredit ? '+' : '-'}${item.amount.toStringAsFixed(2)}',
            style: AppTextStyles.font16Bold.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}
