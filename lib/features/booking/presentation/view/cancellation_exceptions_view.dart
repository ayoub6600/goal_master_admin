import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/cancellation_case.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';

/// Appeals waiting on this venue.
///
/// Shows the money three ways before any decision — what the session was
/// worth, what the customer already got back, and what the venue is holding —
/// because approving means giving back part of the third, and the exact
/// amount is shown before it is confirmed rather than after.
class CancellationExceptionsView extends StatefulWidget {
  const CancellationExceptionsView({super.key});

  @override
  State<CancellationExceptionsView> createState() =>
      _CancellationExceptionsViewState();
}

class _CancellationExceptionsViewState
    extends State<CancellationExceptionsView> {
  List<CancellationExceptionCase> _cases = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final result = await getIt<BookingRepoImp>().pendingExceptions();

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = failure.errMessage;
        _loading = false;
      }),
      (cases) => setState(() {
        _cases = cases;
        _error = null;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'طلبات مراجعة الإلغاء',
      allowBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _cases.isEmpty
                  ? Center(
                      child: Text('ما فيش طلبات بانتظارك.',
                          style: AppTextStyles.font14Regular))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _cases.length,
                        separatorBuilder: (_, __) => HeightSpace(10.h),
                        itemBuilder: (_, i) => _CaseCard(
                          item: _cases[i],
                          onDecided: _load,
                        ),
                      ),
                    ),
    );
  }
}

class _CaseCard extends StatefulWidget {
  const _CaseCard({required this.item, required this.onDecided});

  final CancellationExceptionCase item;
  final VoidCallback onDecided;

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  bool _working = false;

  Future<void> _approve() async {
    final item = widget.item;

    // The exact amount, before confirming — not a percentage, and not a
    // surprise afterwards.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('الموافقة على الطلب؟', style: AppTextStyles.font16Bold),
        content: Text(
          'سيتم استرجاع ${item.retainedAmount.toStringAsFixed(2)} د.ل إضافية '
          'للزبون من المبلغ المحتجز لديك.',
          style: AppTextStyles.font14Regular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _working = true);

    final result = await getIt<BookingRepoImp>()
        .decideException(exceptionId: item.id, decision: 'approve');

    if (!mounted) return;
    setState(() => _working = false);

    result.fold(
      (failure) => _toast(failure.errMessage),
      (message) {
        _toast(message);
        widget.onDecided();
      },
    );
  }

  Future<void> _reject() async {
    final controller = TextEditingController();

    // Required, not optional: the customer sees this, and a refusal they
    // cannot understand is a refusal they will escalate.
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('سبب الرفض', style: AppTextStyles.font16Bold),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب سبباً واضحاً — الزبون بيشوفه.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _working = true);

    final result = await getIt<BookingRepoImp>().decideException(
      exceptionId: widget.item.id,
      decision: 'reject',
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _working = false);

    result.fold((failure) => _toast(failure.errMessage), (message) {
      _toast(message);
      widget.onDecided();
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(item.customer.isEmpty ? 'زبون' : item.customer,
                  style: AppTextStyles.font14Bold),
            ),
            if (item.isMonthly)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text('موعد شهري',
                    style: AppTextStyles.font12Bold
                        .copyWith(color: AppColors.primary)),
              ),
          ]),
          HeightSpace(4.h),
          Text('${item.date} — ${item.time}',
              style: AppTextStyles.font12Regular
                  .copyWith(color: AppColors.fontColor)),
          HeightSpace(10.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(children: [
              _line('قيمة الموعد', item.allocationAmount),
              _line('استرجعه الزبون حسب السياسة', item.policyRefundAmount),
              _line('محتجز لديك', item.retainedAmount, bold: true),
            ]),
          ),
          HeightSpace(10.h),
          Text('السبب: ${item.reasonLabel}', style: AppTextStyles.font12Bold),
          if ((item.reasonText ?? '').isNotEmpty)
            Text(item.reasonText!,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.fontColor)),
          HeightSpace(12.h),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _working ? null : _reject,
                child: const Text('رفض'),
              ),
            ),
            WidthSpace(10.w),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: _working ? null : _approve,
                child: Text(_working ? '...' : 'موافقة',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _line(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold
                  ? AppTextStyles.font12Bold
                  : AppTextStyles.font12Regular
                      .copyWith(color: AppColors.fontColor)),
          Text('${amount.toStringAsFixed(2)} د.ل',
              style: bold
                  ? AppTextStyles.font12Bold.copyWith(color: AppColors.primary)
                  : AppTextStyles.font12Regular),
        ],
      ),
    );
  }
}
