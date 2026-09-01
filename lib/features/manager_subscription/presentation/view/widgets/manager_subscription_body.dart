import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/subscription_plan_card.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';
import 'package:goal_master_admin/features/manager_subscription/presentation/manager/manager_subscription_cubit/manager_subscription_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/subscription_lifecycle.dart';

class ManagerSubscriptionBody extends StatefulWidget {
  const ManagerSubscriptionBody({super.key});

  @override
  State<ManagerSubscriptionBody> createState() =>
      _ManagerSubscriptionBodyState();
}

class _ManagerSubscriptionBodyState extends State<ManagerSubscriptionBody> {
  SubscriptionPlanOption? _selectedPlan;
  String _billingCycle = 'monthly';
  bool _didInitSelection = false;

  void _initSelection(
    ManagerCurrentSubscription? current,
    List<SubscriptionPlanOption> plans,
  ) {
    if (_didInitSelection || plans.isEmpty) return;

    if (current != null) {
      _billingCycle =
          current.billingCycle == 'yearly' ? 'yearly' : 'monthly';
      _selectedPlan = plans.cast<SubscriptionPlanOption?>().firstWhere(
            (plan) => plan?.id == current.planId,
            orElse: () => plans.first,
          );
    } else {
      _selectedPlan = plans.first;
    }

    _didInitSelection = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagerSubscriptionCubit, ManagerSubscriptionState>(
      listener: (context, state) {
        if (state is ManagerSubscriptionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is ManagerSubscriptionInsufficientBalance) {
          _showInsufficientBalanceDialog(context, state);
        }
        if (state is ManagerSubscriptionChangeSuccess) {
          showCustomSuccessToast('تم تحديث اشتراكك بنجاح.');
          context.read<ProfileCubit>().getProfile();
        }
      },
      builder: (context, state) {
        final current = switch (state) {
          final ManagerSubscriptionLoaded s => s.current,
          final ManagerSubscriptionChanging s => s.current,
          final ManagerSubscriptionChangeSuccess s => s.current,
          final ManagerSubscriptionFailure s => s.current,
          final ManagerSubscriptionInsufficientBalance s => s.current,
          _ => null,
        };
        final plans = switch (state) {
          final ManagerSubscriptionLoaded s => s.plans,
          final ManagerSubscriptionChanging s => s.plans,
          final ManagerSubscriptionChangeSuccess s => s.plans,
          final ManagerSubscriptionFailure s => s.plans,
          final ManagerSubscriptionInsufficientBalance s => s.plans,
          _ => const <SubscriptionPlanOption>[],
        };
        final isSubmitting = state is ManagerSubscriptionChanging;
        final isLoading = state is ManagerSubscriptionLoading ||
            state is ManagerSubscriptionInitial;

        _initSelection(current, plans);

        return PageWrapper(
          title: 'الاشتراك',
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current != null) _buildCurrentPlanCard(current),
                      // A change waiting for the cycle to end belongs beside
                      // the current plan, not buried in a card the manager has
                      // to go looking for.
                      if (current?.scheduledChange != null) ...[
                        HeightSpace(12.h),
                        _buildScheduledChangeBanner(current!.scheduledChange!),
                      ],
                      HeightSpace(18.h),
                      Text('اختر باقة', style: AppTextStyles.font18Bold),
                      HeightSpace(10.h),
                      _buildCycleToggle(),
                      HeightSpace(16.h),
                      _buildPlansCard(plans),
                      HeightSpace(18.h),
                      Builder(
                        builder: (context) {
                          final cubit = context.read<ManagerSubscriptionCubit>();
                          final action = _selectedPlan == null
                              ? null
                              : cubit.actionFor(_selectedPlan!.id);

                          // The words and the behaviour both come from the
                          // server's classification. The plan the manager
                          // already holds is not purchasable, so its button
                          // does nothing rather than sending a charge.
                          return ButtonApp(
                            text: isSubmitting
                                ? 'جارٍ الحفظ...'
                                : (action?.label ?? 'اشترك'),
                            backGround: (action?.isActionable ?? true)
                                ? null
                                : AppColors.grey,
                            onTap: isSubmitting ||
                                    _selectedPlan == null ||
                                    !(action?.isActionable ?? true)
                                ? null
                                : () => _confirmAction(context, action!),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showInsufficientBalanceDialog(
    BuildContext context,
    ManagerSubscriptionInsufficientBalance state,
  ) {
    final shortfall =
        (state.requiredAmount - state.currentBalance).toStringAsFixed(2);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: const Color(0xffB25E00)),
              WidthSpace(8.w),
              Expanded(
                child: Text('الرصيد غير كافٍ', style: AppTextStyles.font18Bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رصيدك الحالي ${state.currentBalance.toStringAsFixed(2)} د.ل، والمطلوب لتجديد هذه الباقة ${state.requiredAmount.toStringAsFixed(2)} د.ل (ينقصك $shortfall د.ل).',
                style: AppTextStyles.font14Medium.copyWith(height: 1.6),
              ),
              HeightSpace(8.h),
              Text(
                'اشحن المحفظة أولاً ثم أعد المحاولة.',
                style: AppTextStyles.font14Medium.copyWith(height: 1.6),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            SizedBox(
              width: 150.w,
              child: ButtonApp(
                text: 'اشحن المحفظة',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  push(RoutesKeys.kManagerWallet, context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentPlanCard(ManagerCurrentSubscription current) {
    final showWarning = current.isExpiringSoon || current.isExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xffF4F8F2),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xffD8E7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('باقتك الحالية', style: AppTextStyles.font16Bold),
                  if (current.isTrial) ...[
                    WidthSpace(8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xff1E88E5),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        'تجربة مجانية',
                        style: AppTextStyles.font12Bold
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              HeightSpace(8.h),
              Text(
                current.planName.isNotEmpty ? current.planName : 'بدون باقة',
                style:
                    AppTextStyles.font20Bold.copyWith(color: AppColors.primary),
              ),
              HeightSpace(6.h),
              if (current.isTrial)
                Text(
                  current.trialEndsAt != null
                      ? 'هذه فترة تجريبية مجانية، تنتهي في ${current.trialEndsAt} — لن يتم خصم أي مبلغ من محفظتك حتى تنتهي التجربة.'
                      : 'هذه فترة تجريبية مجانية — لن يتم خصم أي مبلغ من محفظتك حتى تنتهي التجربة.',
                  style: AppTextStyles.font14Medium.copyWith(
                    color: const Color(0xff1E88E5),
                    height: 1.5,
                  ),
                )
              else ...[
                if (current.endsAt != null)
                  Text(
                    'تنتهي في: ${current.endsAt}',
                    style: AppTextStyles.font14Medium,
                  ),
                Text(
                  current.billingCycle == 'yearly'
                      ? 'اشتراك سنوي مدفوع'
                      : 'اشتراك شهري مدفوع',
                  style: AppTextStyles.font14Medium,
                ),
              ],
              HeightSpace(10.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'التجديد التلقائي',
                    style: AppTextStyles.font12Medium.copyWith(
                      color: const Color(0xff8A93A0),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: current.autoRenew,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        context.read<ManagerSubscriptionCubit>().toggleAutoRenew(
                              value,
                            );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showWarning) ...[
          HeightSpace(12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xffFFF4E5),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffF3C98A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: const Color(0xffB25E00), size: 22.sp),
                WidthSpace(10.w),
                Expanded(
                  child: Text(
                    current.isExpired
                        ? 'انتهت صلاحية باقتك. جدد الآن حتى لا تتوقف بعض الميزات.'
                        : 'باقتك ستنتهي خلال ${current.daysRemaining} ${current.daysRemaining == 1 ? 'يوم' : 'أيام'}. جدد الآن لتفادي انقطاع الخدمة.',
                    style: AppTextStyles.font14Bold.copyWith(
                      color: const Color(0xff7A3E00),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCycleToggle() {
    final isMonthly = _billingCycle == 'monthly';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xffF2F4F7),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCycleChip(
              title: 'شهري',
              isActive: isMonthly,
              onTap: () => setState(() => _billingCycle = 'monthly'),
            ),
          ),
          WidthSpace(8.w),
          Expanded(
            child: _buildCycleChip(
              title: 'سنوي',
              isActive: !isMonthly,
              onTap: () => setState(() => _billingCycle = 'yearly'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleChip({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.font14Bold.copyWith(
              color: isActive ? Colors.white : AppColors.fontColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlansCard(List<SubscriptionPlanOption> plans) {
    if (plans.isEmpty) {
      return Text(
        'لا توجد باقات متاحة حاليًا.',
        style: AppTextStyles.font14Medium,
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(6, 18, 31, 0.92),
            Color.fromRGBO(20, 57, 35, 0.92),
          ],
        ),
      ),
      child: Column(
        children: plans
            .map(
              (plan) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: SubscriptionPlanCard(
                  plan: plan,
                  billingCycle: _billingCycle,
                  isSelected: _selectedPlan?.id == plan.id,
                  onTap: () => setState(() => _selectedPlan = plan),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// A change the manager has already asked for, waiting for the cycle to end.
  Widget _buildScheduledChangeBanner(ScheduledSubscriptionChange scheduled) {
    final when = scheduled.effectiveAt;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight2,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat, size: 18.w, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text('تغيير مجدول',
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            when == null
                ? 'سيتم التحويل إلى باقة ${scheduled.planName} عند انتهاء اشتراكك الحالي.'
                : 'سيتم التحويل إلى باقة ${scheduled.planName} عند انتهاء '
                    'اشتراكك الحالي في ${arabicDayAndDateOf(when)}.',
            style: AppTextStyles.font14Regular
                .copyWith(color: AppColors.uiBlack),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmCancelScheduled(context, scheduled),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, 44.h),
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text('إلغاء التغيير',
                  style: AppTextStyles.font14Bold
                      .copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelScheduled(
    BuildContext context,
    ScheduledSubscriptionChange scheduled,
  ) async {
    final cubit = context.read<ManagerSubscriptionCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء تغيير الباقة؟'),
          content: Text(
            'ستستمر على باقتك الحالية ولن يتم التحويل إلى ${scheduled.planName}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('رجوع'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إلغاء التغيير'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.cancelScheduledChange();
    }
  }

  /// Everything a financial or scheduling tap has to say before it happens.
  ///
  /// Amounts shown here are the server's, carried on the lifecycle payload —
  /// the app never recomputes what an upgrade costs.
  Future<void> _confirmAction(BuildContext context, PlanAction action) async {
    final cubit = context.read<ManagerSubscriptionCubit>();
    final plan = _selectedPlan!;
    final info = cubit.lifecycleFor(plan.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(switch (action) {
            PlanAction.upgrade => 'ترقية الباقة',
            PlanAction.renew => 'تجديد الاشتراك',
            PlanAction.scheduleDowngrade ||
            PlanAction.scheduleSwitch =>
              'تغيير الباقة',
            _ => 'تأكيد الاشتراك',
          }),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _confirmationLines(action, plan.name, info),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('رجوع'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(switch (action) {
                PlanAction.upgrade => 'تأكيد الترقية',
                PlanAction.renew => 'تأكيد التجديد',
                _ => 'تأكيد التغيير',
              }),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await cubit.changePlan(
      subscriptionPlanId: plan.id,
      billingCycle: _billingCycle,
    );
  }

  List<Widget> _confirmationLines(
    PlanAction action,
    String planName,
    PlanLifecycle? info,
  ) {
    final preview = info?.upgradePreview;
    final money = (double v) => '${v.toStringAsFixed(2)} د.ل';

    if (action == PlanAction.upgrade && preview != null) {
      return [
        _confirmRow('الباقة الحالية', preview.currentPlanName),
        _confirmRow('الباقة الجديدة', planName),
        if (preview.cycleEndsAt != null)
          _confirmRow('باقتك الحالية مستمرة حتى',
              arabicDayAndDateOf(preview.cycleEndsAt!)),
        const Divider(),
        _confirmRow('قيمة الفترة المتبقية من باقتك الحالية',
            money(preview.unusedCurrentValue)),
        _confirmRow('قيمة الباقة الجديدة للفترة المتبقية',
            money(preview.targetPeriodValue)),
        _confirmRow('المبلغ المطلوب الآن', money(preview.amountDue), bold: true),
        SizedBox(height: 8.h),
        Text('لن تبدأ دورة جديدة. سيبقى تاريخ انتهاء اشتراكك كما هو.',
            style: AppTextStyles.font12Regular
                .copyWith(color: AppColors.fontColor)),
      ];
    }

    if (action.isScheduled) {
      return [
        Text('ستستمر باقتك الحالية حتى نهاية الدورة، ثم سيتم التحويل إلى '
            '$planName.'),
        SizedBox(height: 8.h),
        Text(
          action == PlanAction.scheduleSwitch
              ? 'لن يتم تغيير مزايا باقتك الحالية الآن. لن يتم خصم أي مبلغ الآن.'
              : 'لن يتم خصم أي مبلغ الآن.',
          style: AppTextStyles.font12Regular
              .copyWith(color: AppColors.fontColor),
        ),
      ];
    }

    // Renewal or a first purchase.
    return [
      _confirmRow('الباقة', planName),
      if (info != null && info.hasPromotionalPrice) ...[
        _confirmRow('السعر الأساسي', money(info.listPrice)),
        _confirmRow('سعر العرض', money(info.effectivePrice)),
      ],
      _confirmRow(
        'المبلغ النهائي',
        money(info?.effectivePrice ?? 0),
        bold: true,
      ),
    ];
  }

  /// One line of a confirmation sheet.
  ///
  /// The label and the value share a row, and «قيمة الفترة المتبقية من باقتك
  /// الحالية» beside an amount is wider than a dialog — so both sides flex and
  /// the label is allowed to wrap rather than overflowing the edge.
  Widget _confirmRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.font12Regular
                  .copyWith(color: AppColors.fontColor),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: bold
                  ? AppTextStyles.font14Bold
                  : AppTextStyles.font14Regular,
            ),
          ),
        ],
      ),
    );
  }
}
