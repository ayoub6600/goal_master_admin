import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/model/manager_cancellation_policy_response.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/repo/manager_cancellation_policy_repo_imp.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/presentation/manager/manager_cancellation_policy_cubit/manager_cancellation_policy_cubit.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/presentation/manager/manager_cancellation_policy_cubit/manager_cancellation_policy_state.dart';

class ManagerCancellationPolicyView extends StatelessWidget {
  const ManagerCancellationPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerCancellationPolicyCubit(
        getIt<ManagerCancellationPolicyRepoImp>(),
      )..load(),
      child: const _ManagerCancellationPolicyBody(),
    );
  }
}

class _ManagerCancellationPolicyBody extends StatefulWidget {
  const _ManagerCancellationPolicyBody();

  @override
  State<_ManagerCancellationPolicyBody> createState() =>
      _ManagerCancellationPolicyBodyState();
}

class _ManagerCancellationPolicyBodyState
    extends State<_ManagerCancellationPolicyBody> {
  double? _free;
  double? _p75;
  double? _p50;
  bool _saving = false;

  Future<void> _save(ManagerCancellationPolicyData data) async {
    final free = _free ?? data.hoursFor(100);
    final p75 = _p75 ?? data.hoursFor(75);
    final p50 = _p50 ?? data.hoursFor(50);

    setState(() => _saving = true);

    final result = await getIt<ManagerCancellationPolicyRepoImp>().updatePolicy(
      freeHours: free,
      partial75Hours: p75,
      partial50Hours: p50,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.errMessage))),
      (message) async {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        await context.read<ManagerCancellationPolicyCubit>().load();
        if (mounted) {
          setState(() {
            _free = null;
            _p75 = null;
            _p50 = null;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'سياسة الإلغاء',
      child: BlocBuilder<ManagerCancellationPolicyCubit,
          ManagerCancellationPolicyState>(
        builder: (context, state) {
          if (state is ManagerCancellationPolicyLoading ||
              state is ManagerCancellationPolicyInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ManagerCancellationPolicyFailure) {
            return Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.read<ManagerCancellationPolicyCubit>().load(),
                child: const Text('إعادة المحاولة'),
              ),
            );
          }

          final data = (state as ManagerCancellationPolicyLoaded).data;
          final free = _free ?? data.hoursFor(100);
          final p75 = _p75 ?? data.hoursFor(75);
          final p50 = _p50 ?? data.hoursFor(50);
          final minFree = data.bounds.minFreeCancellationHours;
          final maxFree = data.bounds.maxFreeCancellationHours;
          final canEdit = data.bounds.allowOverride && !_saving;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!data.bounds.policyEnabled)
                _banner(
                  'نظام رسوم الإلغاء غير مفعّل حالياً على مستوى المنصة، فإعدادك هنا لن يُطبّق بعد.',
                  Colors.orange.shade800,
                )
              else if (!data.bounds.allowOverride)
                _banner(
                  'تخصيص سياسة الإلغاء لكل ملعب غير متاح حالياً — تواصل مع جول ماستر.',
                  Colors.orange.shade800,
                ),
              HeightSpace(12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: const Color(0xffD7E8D3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سياسة الإلغاء', style: AppTextStyles.font18Bold),
                    HeightSpace(8.h),
                    Text(
                      'حدد عدد الساعات قبل الموعد لكل مرحلة استرجاع. '
                      'كل ما اقترب الزبون من وقت اللعب، قلّت نسبة الاسترجاع.',
                      style: AppTextStyles.font14Regular.copyWith(height: 1.5),
                    ),
                    HeightSpace(20.h),
                    _tierRow(
                      label: 'مجاني بالكامل (100%) من',
                      hours: free,
                      color: AppColors.primary,
                      min: minFree,
                      max: maxFree,
                      canEdit: canEdit,
                      onChanged: (v) => setState(() => _free = v),
                    ),
                    HeightSpace(16.h),
                    _tierRow(
                      label: 'استرجاع 75% من',
                      hours: p75,
                      color: const Color(0xFF4C8C4A),
                      min: 0,
                      max: free > 0 ? free - 0.5 : 0,
                      canEdit: canEdit,
                      onChanged: (v) => setState(() => _p75 = v),
                    ),
                    HeightSpace(16.h),
                    _tierRow(
                      label: 'استرجاع 50% من',
                      hours: p50,
                      color: const Color(0xFFBA4A00),
                      min: 0,
                      max: p75 > 0 ? p75 - 0.5 : 0,
                      canEdit: canEdit,
                      onChanged: (v) => setState(() => _p50 = v),
                    ),
                    HeightSpace(12.h),
                    _note(
                      'أقل من ${_fmt(p50)} ساعة: بدون استرجاع (0%).',
                      Colors.grey.shade600,
                    ),
                    HeightSpace(8.h),
                    Text(
                      'الحد المسموح للمجانية الكاملة بين ${minFree.toStringAsFixed(0)} و${maxFree.toStringAsFixed(0)} ساعة.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font12Regular
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    HeightSpace(20.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: canEdit ? () => _save(data) : null,
                        child: Text(
                          _saving ? 'جارٍ الحفظ...' : 'حفظ',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tierRow({
    required String label,
    required double hours,
    required Color color,
    required double min,
    required double max,
    required bool canEdit,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.font14Regular.copyWith(
              color: Colors.grey.shade800,
            ),
          ),
        ),
        _stepButton(
          icon: Icons.remove,
          onTap: canEdit && hours > min
              ? () => onChanged((hours - 0.5).clamp(min, max))
              : null,
        ),
        SizedBox(
          width: 64.w,
          child: Text(
            '${_fmt(hours)} س',
            textAlign: TextAlign.center,
            style: AppTextStyles.font16Medium.copyWith(color: color),
          ),
        ),
        _stepButton(
          icon: Icons.add,
          onTap: canEdit && hours < max
              ? () => onChanged((hours + 0.5).clamp(min, max))
              : null,
        ),
      ],
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _stepButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: onTap == null ? Colors.grey : AppColors.primary,
        ),
      ),
    );
  }

  Widget _note(String text, Color color) {
    return Text(text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5.sp, color: color, height: 1.45));
  }

  Widget _banner(String text, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5.sp, color: color, height: 1.5),
      ),
    );
  }
}
