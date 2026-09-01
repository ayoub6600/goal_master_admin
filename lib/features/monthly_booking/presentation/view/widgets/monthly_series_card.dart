import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/core/utils/money.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';

/// One recurring booking, as one card.
///
/// Reads top to bottom the way a manager asks the questions: what is this and
/// is it still running, who is it for, when do they play next, what am I owed,
/// what can I do. The database identifiers that used to headline the card are
/// still here — a manager quoting a number to support needs them — but as a
/// small reference under the title rather than as the loudest thing on screen.
class MonthlySeriesCard extends StatelessWidget {
  const MonthlySeriesCard({
    super.key,
    required this.group,
    required this.now,
    this.onDetails,
    this.onMenu,
  });

  final MonthlySeriesGroup group;

  /// Injected so "next" is testable and never drifts mid-frame.
  final DateTime now;

  final VoidCallback? onDetails;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.inactive5),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _who(),
                SizedBox(height: 12.h),
                _when(),
                SizedBox(height: 12.h),
                _money(),
                SizedBox(height: 14.h),
                _actions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Header -----------------------------------------------------------

  Widget _header() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.repeat_rounded,
                size: 16.r, color: AppColors.primary),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حجز شهري',
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.dark),
                ),
                SizedBox(height: 1.h),
                Text(
                  '#${group.reference}',
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.dark2),
                ),
              ],
            ),
          ),
          StatusChip(
            label: group.isActive ? 'مفعّل' : 'منتهي',
            tone: group.isActive ? ChipTone.positive : ChipTone.neutral,
          ),
        ],
      ),
    );
  }

  // ---- Who and where ----------------------------------------------------

  Widget _who() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(
          Icons.person_outline_rounded,
          group.customerName.isEmpty ? 'عميل غير محدد' : group.customerName,
          bold: true,
        ),
        SizedBox(height: 6.h),
        _line(
          Icons.place_outlined,
          group.branchName.isEmpty ? 'ملعب غير محدد' : group.branchName,
        ),
      ],
    );
  }

  Widget _line(IconData icon, String text, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.r, color: AppColors.dark2),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (bold
                    ? AppTextStyles.font14SemiBold
                    : AppTextStyles.font14Regular)
                .copyWith(color: bold ? AppColors.dark : AppColors.dark5),
          ),
        ),
      ],
    );
  }

  // ---- When -------------------------------------------------------------

  Widget _when() {
    final next = group.nextOccurrence(now);
    final position = group.nextPosition(now);

    // Nothing upcoming: the last session is shown as what it is. Labelling a
    // date in the past «الموعد القادم» is the one thing this card must never
    // do — a manager would plan their week around it.
    final occurrence = next ?? group.lastOccurrence;
    final isUpcoming = next != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: isUpcoming ? AppColors.lightSuccess : AppColors.inactive3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isUpcoming ? 'الموعد القادم' : 'آخر موعد',
                style: AppTextStyles.font12SemiBold.copyWith(
                  color: isUpcoming ? AppColors.success : AppColors.dark2,
                ),
              ),
              const Spacer(),
              if (isUpcoming && position != null && group.isSeries)
                Flexible(
                  child: Text(
                    'الموعد $position من ${group.totalCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12Regular
                        .copyWith(color: AppColors.dark2),
                  ),
                ),
              if (!isUpcoming && group.isSeries)
                Flexible(
                  child: Text(
                    'اكتملت ${group.playedCount} من ${group.totalCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12Regular
                        .copyWith(color: AppColors.dark2),
                  ),
                ),
            ],
          ),
          SizedBox(height: 7.h),
          if (occurrence == null)
            Text('لا توجد مواعيد',
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.dark2))
          else ...[
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14.r, color: AppColors.dark2),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _dateLabel(occurrence),
                    style: AppTextStyles.font14SemiBold
                        .copyWith(color: AppColors.dark),
                  ),
                ),
                if (occurrence.isReplacement) const ReplacementBadge(),
              ],
            ),
            SizedBox(height: 5.h),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14.r, color: AppColors.dark2),
                SizedBox(width: 6.w),
                Expanded(child: SlotTime(occurrence: occurrence)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _dateLabel(MonthlyBookingResponse o) {
    final date = MonthlySeriesGroup.occurrenceDate(o);
    if (date == null) return '';

    return '${arabicDayAndDateOf(date)} ${date.year}';
  }

  // ---- Money ------------------------------------------------------------

  Widget _money() {
    final state = group.paymentState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusChip(label: state.label, tone: state.tone),
            const Spacer(),
            if (group.isSeries)
              Flexible(
                child: Text(
                  '${group.totalCount} مواعيد',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.dark2),
                ),
              ),
          ],
        ),
        SizedBox(height: 9.h),
        MoneyRow(label: 'الإجمالي', amount: group.totalAmount),
        SizedBox(height: 4.h),
        MoneyRow(label: 'تم استلام', amount: group.paidAmount),
        SizedBox(height: 4.h),
        MoneyRow(
          label: 'المتبقي',
          amount: group.remainingAmount,
          emphasise: group.remainingAmount > 0,
        ),
      ],
    );
  }

  // ---- Actions ----------------------------------------------------------

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onDetails,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'عرض التفاصيل',
                  style: AppTextStyles.font14Bold
                      .copyWith(color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: onMenu,
          child: Container(
            width: 44.w,
            height: 42.h,
            decoration: BoxDecoration(
              color: AppColors.inactive3,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.inactive4),
            ),
            child: Icon(Icons.more_horiz_rounded,
                size: 20.r, color: AppColors.dark),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

enum ChipTone { positive, warning, danger, neutral, info }

extension PaymentTone on SeriesPaymentState {
  ChipTone get tone => switch (this) {
        SeriesPaymentState.settled => ChipTone.positive,
        SeriesPaymentState.partial => ChipTone.warning,
        SeriesPaymentState.unpaid => ChipTone.danger,
      };
}

/// A state in one glance. Colour carries meaning here, so the palette stays
/// small: green settled, amber part-way, red owed, grey inert.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.positive => (AppColors.lightSuccess, AppColors.success),
      ChipTone.warning => (const Color(0xFFFFF3E0), const Color(0xFFB26A00)),
      ChipTone.danger => (AppColors.dangerLight1, AppColors.errorRed),
      ChipTone.info => (const Color(0xFFEAF4FB), AppColors.lightBlue),
      ChipTone.neutral => (AppColors.inactive2, AppColors.dark2),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12SemiBold.copyWith(color: fg),
      ),
    );
  }
}

/// Marks a session the venue moved off the recurring pattern.
///
/// Shown from the server's own flag. A different clock time is not evidence of
/// a replacement, and this badge never appears because two times differ.
class ReplacementBadge extends StatelessWidget {
  const ReplacementBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      const StatusChip(label: 'موعد بديل', tone: ChipTone.info);
}

/// A slot, laid out left-to-right as one unit.
///
/// Latin digits inside an Arabic paragraph get reordered by the bidi algorithm
/// — «8:00 – 9:00 مساءً» becomes a range whose start and end have swapped. The
/// numbers are isolated so the range always reads in the order it happens.
class SlotTime extends StatelessWidget {
  const SlotTime({super.key, required this.occurrence, this.style});

  final MonthlyBookingResponse occurrence;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Read from start_at/end_at where the server sent them, so the slot on
    // screen is the slot the booking engine holds.
    final startAt = MonthlySeriesGroup.occurrenceStart(occurrence);
    final endAt = MonthlySeriesGroup.occurrenceEnd(occurrence);

    final start = startAt == null ? null : (startAt.hour, startAt.minute);
    final end = endAt == null ? null : (endAt.hour, endAt.minute);

    if (start == null || end == null) {
      return Text(occurrence.startTime, style: style);
    }

    final textStyle =
        style ?? AppTextStyles.font14Regular.copyWith(color: AppColors.dark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            rangeText(start, end),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(arabicDayPeriodOf(start.$1, start.$2), style: textStyle),
      ],
    );
  }

  static String _clock((int, int) t) {
    final hour12 = t.$1 % 12 == 0 ? 12 : t.$1 % 12;
    return '$hour12:${t.$2.toString().padLeft(2, '0')}';
  }

  /// The range as one left-to-right unit: start, dash, end — in that order.
  ///
  /// Wrapped in an explicit directional isolate (U+2066 … U+2069) rather than
  /// relying on the widget's own `textDirection`. The dash and the spaces are
  /// bidi-neutral, so in an Arabic paragraph the two clock times can be
  /// reordered around them and a 5–6pm booking then reads as «6:00 – 5:00»:
  /// still a valid-looking range, with the start and the end swapped. The
  /// isolate makes that impossible wherever this string is placed.
  static String rangeText((int, int) start, (int, int) end) =>
      '\u2066${_clock(start)} – ${_clock(end)}\u2069';

  /// The time of day out of either «20:00:00» or «2026-08-30 20:00:00».
  ///
  /// The date half of the DATETIME is a schema artefact and is discarded; the
  /// session's real day comes from its `date` column.
  static (int, int)? clockOf(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final full = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (full != null) return (full.hour, full.minute);

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;

    return (hour, minute);
  }
}

/// One line of the financial summary: label on one side, amount on the other.
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.amount,
    this.emphasise = false,
  });

  final String label;
  final double amount;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12Regular.copyWith(color: AppColors.dark2),
          ),
        ),
        const Spacer(),
        Text(
          formatMoney(amount),
          // The amount is digits followed by an Arabic currency word; isolating
          // it keeps «164 د.ل» from rendering as «د.ل 164».
          textDirection: TextDirection.rtl,
          style: (emphasise
                  ? AppTextStyles.font14Bold
                  : AppTextStyles.font14SemiBold)
              .copyWith(color: emphasise ? AppColors.errorRed : AppColors.dark),
        ),
      ],
    );
  }
}
