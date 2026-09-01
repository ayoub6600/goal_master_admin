import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/core/utils/money.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';

/// Everything the venue holds on one recurring booking, and its sessions.
///
/// Built from the sessions the list already returned, so opening it costs no
/// request and shows exactly the rows the card was summarising. Each session
/// keeps its own date and its own clock time: a replacement week legitimately
/// sits at a different hour, and flattening them all to the series slot would
/// tell the manager a pitch is free when it is not.
class MonthlySeriesSheet extends StatelessWidget {
  const MonthlySeriesSheet({
    super.key,
    required this.group,
    required this.now,
    this.onOccurrenceTap,
  });

  final MonthlySeriesGroup group;
  final DateTime now;
  final void Function(MonthlyBookingResponse occurrence)? onOccurrenceTap;

  @override
  Widget build(BuildContext context) {
    final next = group.nextOccurrence(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'حجز شهري #${group.reference}',
                style: AppTextStyles.font16Bold.copyWith(color: AppColors.dark),
              ),
            ),
            StatusChip(
              label: group.isActive ? 'مفعّل' : 'منتهي',
              tone: group.isActive ? ChipTone.positive : ChipTone.neutral,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        _fact('العميل', group.customerName),
        if (group.customerPhone.isNotEmpty)
          _fact('رقم الهاتف', group.customerPhone, ltr: true),
        _fact('الملعب', group.branchName),
        _fact('عدد المواعيد', '${group.totalCount}'),
        if (group.isSeries)
          _fact('التقدّم', 'اكتملت ${group.playedCount} من ${group.totalCount}'),
        SizedBox(height: 14.h),
        _paymentBlock(),
        SizedBox(height: 16.h),
        Text('المواعيد',
            style: AppTextStyles.font14Bold.copyWith(color: AppColors.dark)),
        SizedBox(height: 8.h),
        ...group.occurrences.map(
          (o) => _OccurrenceRow(
            occurrence: o,
            isNext: identical(o, next),
            onTap: onOccurrenceTap == null ? null : () => onOccurrenceTap!(o),
          ),
        ),
      ],
    );
  }

  Widget _fact(String label, String value, {bool ltr = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96.w,
            child: Text(label,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.dark2)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: ltr ? TextAlign.right : null,
              style: AppTextStyles.font14SemiBold
                  .copyWith(color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBlock() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              StatusChip(
                label: group.paymentState.label,
                tone: group.paymentState.tone,
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 10.h),
          MoneyRow(label: 'الإجمالي', amount: group.totalAmount),
          SizedBox(height: 5.h),
          MoneyRow(label: 'تم استلام', amount: group.paidAmount),
          SizedBox(height: 5.h),
          MoneyRow(
            label: 'المتبقي',
            amount: group.remainingAmount,
            emphasise: group.remainingAmount > 0,
          ),
        ],
      ),
    );
  }
}

/// One session in the list: what happened to it, when, and for how much.
class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({
    required this.occurrence,
    required this.isNext,
    this.onTap,
  });

  final MonthlyBookingResponse occurrence;
  final bool isNext;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = MonthlySeriesGroup.occurrenceDate(occurrence);
    final cancelled = occurrence.isCancelled;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isNext ? AppColors.lightSuccess : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isNext ? AppColors.success : AppColors.inactive5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              cancelled
                  ? Icons.cancel_outlined
                  : occurrence.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
              size: 18.r,
              color: cancelled
                  ? AppColors.errorRed
                  : occurrence.isDone
                      ? AppColors.success
                      : AppColors.dark2,
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and badges wrap rather than compete for one line.
                  //
                  // A replacement week that is also awaiting a result carries
                  // two chips, and squeezing all three onto one row truncated
                  // the date to «الإثنين 24 أغسط…» — losing the single field
                  // the manager is actually scanning for.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        date == null
                            ? '—'
                            : '${arabicDayAndDateOf(date)} ${date.year}',
                        style: AppTextStyles.font14SemiBold.copyWith(
                          color: cancelled ? AppColors.dark2 : AppColors.dark,
                          decoration:
                              cancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (occurrence.isReplacement) const ReplacementBadge(),
                      // Four weeks can end four different ways. The result of
                      // each is shown against the week it belongs to.
                      if (occurrence.hasReportedResult)
                        StatusChip(
                          label: occurrence.attendanceLabel,
                          tone: switch (occurrence.attendanceStatus) {
                            'attended' => ChipTone.positive,
                            'no_show' => ChipTone.danger,
                            _ => ChipTone.warning,
                          },
                        )
                      else if (occurrence.canReportAttendance)
                        const StatusChip(
                          label: 'بانتظار النتيجة',
                          tone: ChipTone.warning,
                        ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      SlotTime(
                        occurrence: occurrence,
                        style: AppTextStyles.font12Regular
                            .copyWith(color: AppColors.dark2),
                      ),
                      const Spacer(),
                      Text(
                        formatMoney(occurrence.serviceAmount > 0
                            ? occurrence.serviceAmount
                            : occurrence.totalAmount),
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.font12Regular
                            .copyWith(color: AppColors.dark2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 4.w),
              Icon(Icons.chevron_left, size: 18.r, color: AppColors.dark2),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ends a recurring booking, with the scope spelled out before it happens.
///
/// Two things a manager must never have to guess: that this covers the whole
/// booking rather than the session in front of them, and that the sessions
/// already played are not being erased. Both are stated in the confirmation,
/// with the exact date the cancellation starts from.
Future<void> confirmEndSeries({
  required BuildContext context,
  required MonthlySeriesGroup group,
  required DateTime now,
  required Future<void> Function() onConfirm,
}) async {
  final next = group.nextOccurrence(now);
  final remaining = group.occurrences
      .where((o) => !o.isCancelled)
      .where((o) {
        final d = MonthlySeriesGroup.occurrenceDate(o);
        return d != null &&
            !d.isBefore(DateTime(now.year, now.month, now.day));
      })
      .length;

  final fromDate = next == null
      ? null
      : MonthlySeriesGroup.occurrenceDate(next);

  baseBottomSheet(
    title: 'إنهاء الحجز الشهري؟',
    context: context,
    hideNavBar: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.dangerLight1,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18.r, color: AppColors.errorRed),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: Text(
                      'هذا الإجراء يشمل الحجز الشهري بالكامل',
                      style: AppTextStyles.font14Bold
                          .copyWith(color: AppColors.errorRed),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 9.h),
              Text(
                fromDate == null
                    ? 'سيتم إلغاء المواعيد المتبقية في هذا الحجز الشهري.'
                    : 'سيتم إلغاء جميع المواعيد من '
                        '${arabicDayAndDateOf(fromDate)} ${fromDate.year} وما بعده'
                        '${remaining > 0 ? ' ($remaining مواعيد)' : ''}.',
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.dark),
              ),
              SizedBox(height: 6.h),
              Text(
                'المواعيد السابقة ستبقى محفوظة كما هي.',
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.dark2),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _SheetButton(
                label: 'تراجع',
                background: AppColors.inactive2,
                foreground: AppColors.dark,
                onTap: () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _SheetButton(
                label: 'إنهاء الحجز الشهري',
                background: AppColors.errorRed,
                foreground: AppColors.white,
                onTap: () {
                  Navigator.pop(context);
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.font14Bold.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Runs the series cancellation and reports what happened.
Future<void> runEndSeries(
  BuildContext context,
  MonthlySeriesGroup group,
) async {
  final cubit = context.read<MonthlyBookingCubit>();
  final result =
      await cubit.bookingRepo.cancelSeries(seriesId: group.seriesId);

  result.fold(
    (failure) => showCustomFailureToast(failure.errMessage),
    (message) {
      showCustomSuccessToast(message);
      cubit.refresh();
    },
  );
}
