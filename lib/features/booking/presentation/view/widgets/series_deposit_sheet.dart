import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_series.dart';

/// Takes a payment against a whole monthly booking.
///
/// The manager enters one amount for the series; which sessions it covers is
/// the server's decision, earliest first. The preview below the field says
/// what that will mean so the split is not a surprise after the fact — it is
/// only a preview, and the figures the screen shows afterwards are the ones
/// the server actually recorded.
class SeriesDepositSheet extends StatefulWidget {
  const SeriesDepositSheet({super.key, required this.series});

  final ManagerSeries series;

  /// Returns the amount to record, or null if the manager backed out.
  static Future<double?> show(BuildContext context, ManagerSeries series) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => SeriesDepositSheet(series: series),
    );
  }

  @override
  State<SeriesDepositSheet> createState() => _SeriesDepositSheetState();
}

class _SeriesDepositSheetState extends State<SeriesDepositSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _entered => double.tryParse(_controller.text.trim()) ?? 0;

  /// Sessions still owed something, earliest first — the order the payment
  /// fills them in.
  List<SeriesOccurrence> get _owing => widget.series.occurrences
      .where((o) => !o.isCancelled && o.remainingDue > 0)
      .toList();

  /// What `amount` would settle, mirroring the server's oldest-first rule.
  ///
  /// A preview only. The server does the real allocation and caps an
  /// overpayment at what is outstanding, so this never decides anything.
  (int settled, double partOf) _preview(double amount) {
    var remaining = amount;
    var settled = 0;

    for (final occurrence in _owing) {
      if (remaining <= 0) break;

      if (remaining >= occurrence.remainingDue) {
        remaining -= occurrence.remainingDue;
        settled++;
      } else {
        return (settled, remaining);
      }
    }

    return (settled, 0);
  }

  String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final outstanding = series.remainingTotal;
    final amount = _entered;
    final overpaying = amount > outstanding;
    final (settled, partOf) = _preview(amount.clamp(0, outstanding));

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xffD7DDE3),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          HeightSpace(16.h),
          Text('تسجيل دفعة', style: AppTextStyles.font18Bold),
          HeightSpace(4.h),
          Text(
            'المبلغ يُوزَّع على المواعيد بالترتيب — الأقدم أولاً.',
            style: AppTextStyles.font12Regular
                .copyWith(color: AppColors.fontColor),
          ),
          HeightSpace(16.h),
          _totals(series),
          HeightSpace(16.h),
          Text('المبلغ المستلم', style: AppTextStyles.font14Bold),
          HeightSpace(8.h),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.font18Bold,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'دينار',
              filled: true,
              fillColor: const Color(0xffFAFBFC),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xffD7DDE3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xffD7DDE3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
          HeightSpace(10.h),
          _quickFills(series, outstanding),
          if (amount > 0) ...[
            HeightSpace(14.h),
            _previewBox(
              settled: settled,
              partOf: partOf,
              overpaying: overpaying,
              outstanding: outstanding,
            ),
          ],
          HeightSpace(20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xffD7DDE3),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: amount <= 0
                  ? null
                  : () => Navigator.of(context).pop(
                        amount.clamp(0, outstanding).toDouble(),
                      ),
              child: Text(
                'تسجيل الدفعة',
                style: AppTextStyles.font16Bold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totals(ManagerSeries series) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _totalCell('الإجمالي', series.grossTotal, AppColors.fontColor),
          _divider(),
          _totalCell('المدفوع', series.paidTotal, AppColors.primary),
          _divider(),
          _totalCell(
            'المتبقي',
            series.remainingTotal,
            const Color(0xFFB26A00),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30.h,
        color: const Color(0xffE1E6EB),
      );

  Widget _totalCell(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.font12Regular
                .copyWith(color: AppColors.fontColor),
          ),
          HeightSpace(4.h),
          Text(
            '${_money(value)} د',
            style: AppTextStyles.font16Bold.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// The two amounts a manager actually reaches for: one session, or the lot.
  Widget _quickFills(ManagerSeries series, double outstanding) {
    final oneSession = _owing.isEmpty ? 0.0 : _owing.first.remainingDue;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        if (oneSession > 0 && oneSession < outstanding)
          _chip('موعد واحد (${_money(oneSession)})', oneSession),
        if (outstanding > 0)
          _chip('المتبقي كاملاً (${_money(outstanding)})', outstanding),
      ],
    );
  }

  Widget _chip(String label, double value) {
    return InkWell(
      onTap: () {
        _controller.text = _money(value);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.font12Bold.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _previewBox({
    required int settled,
    required double partOf,
    required bool overpaying,
    required double outstanding,
  }) {
    final lines = <String>[];

    if (settled > 0) {
      lines.add('يغطي $settled ${settled == 1 ? "موعدًا" : "مواعيد"} بالكامل');
    }
    if (partOf > 0) {
      lines.add('ويدفع ${_money(partOf)} د من الموعد التالي');
    }
    if (lines.isEmpty) {
      lines.add('يُسجَّل كدفعة جزئية على الموعد الأول');
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 15.sp, color: AppColors.primary),
              WidthSpace(6.w),
              Text(
                lines.join('، '),
                style:
                    AppTextStyles.font12Bold.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          // Typing more than is owed is a slip worth naming before it is sent,
          // not after the server has quietly trimmed it.
          if (overpaying) ...[
            HeightSpace(8.h),
            Text(
              'المبلغ أكبر من المتبقي — سيُسجَّل ${_money(outstanding)} د فقط.',
              style: AppTextStyles.font12Bold
                  .copyWith(color: const Color(0xFFB26A00)),
            ),
          ],
        ],
      ),
    );
  }
}
