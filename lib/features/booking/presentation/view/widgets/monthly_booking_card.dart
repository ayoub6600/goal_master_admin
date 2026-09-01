import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';

/// A recurring booking in the venue's list — one card for the whole thing.
///
/// Deliberately unlike the single-booking card: a monthly request is four
/// sessions of pitch time decided in one go, and it should not be mistaken
/// for the one-off bookings it sits among.
class MonthlyBookingCard extends StatefulWidget {
  const MonthlyBookingCard({super.key, required this.booking, this.onChanged});

  final BookingItemResponce booking;

  /// Lets the list refresh after a decision, so what is shown is what the
  /// server recorded rather than a local guess.
  final VoidCallback? onChanged;

  @override
  State<MonthlyBookingCard> createState() => _MonthlyBookingCardState();
}

class _MonthlyBookingCardState extends State<MonthlyBookingCard> {
  bool _deciding = false;

  static const _approved = 2;
  static const _cancelled = 3;

  BookingItemResponce get _booking => widget.booking;

  /// ServiceStatus::Processing — still waiting on the venue.
  bool get _awaitingDecision => _booking.status == 1;

  bool get _hasGap => _booking.seriesSkippedCount > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => push(
        RoutesKeys.kManagerSeriesDetails,
        context,
        extra: _booking.seriesId,
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // The accent stripe: recognisable at a glance while scrolling.
              Container(
                width: 5.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(14.r),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerRow(),
                      HeightSpace(10.h),
                      _customerRow(),
                      HeightSpace(8.h),
                      _detailsBox(),
                      HeightSpace(10.h),
                      _totalRow(),
                      if (_awaitingDecision) ...[
                        HeightSpace(12.h),
                        _decisionButtons(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_repeat, size: 15.sp, color: AppColors.primary),
              WidthSpace(5.w),
              Text(
                'حجز شهري',
                style:
                    AppTextStyles.font12Bold.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (_awaitingDecision)
          _chip(
              'بانتظار قرارك', const Color(0xFFB26A00), const Color(0xFFFFF4E5))
        else
          Flexible(
            child: Text(
              _booking.statusName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.font12Bold.copyWith(color: AppColors.fontColor),
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, Color fg, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label, style: AppTextStyles.font12Bold.copyWith(color: fg)),
    );
  }

  Widget _customerRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 15.w,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Icon(Icons.person, size: 17.sp, color: AppColors.primary),
        ),
        WidthSpace(10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _booking.customer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font14Bold,
              ),
              Text(
                '${_booking.service} • ${_booking.employee}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.fontColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The commitment, one fact per line.
  ///
  /// Previously the count and the date span shared a Row, and the span — a
  /// raw ISO timestamp — overflowed by 150px. Stacking them removes the
  /// competition for width entirely, and the dates are now readable.
  Widget _detailsBox() {
    final count = _booking.seriesOccurrenceCount;
    // Both come from the server already formatted — deriving them from the
    // UTC-serialised datetimes is what showed Saturday for a Sunday booking.
    final weekday = arabicWeekday(_booking.seriesStartsOn);
    final time = arabicTime(_booking.displayStartTime);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _factLine(
            Icons.event_repeat,
            weekday.isEmpty
                ? '$count مواعيد'
                : '$count مواعيد — كل $weekday الساعة $time',
            AppColors.fontColor,
          ),
          HeightSpace(6.h),
          _factLine(
            Icons.calendar_month,
            'من ${arabicShortDate(_booking.seriesStartsOn)} '
            'إلى ${arabicDateWithYear(_booking.seriesEndsOn)}',
            AppColors.fontColor,
          ),
          // The gap matters before accepting: these are four sessions, but
          // not four consecutive weeks, and the last falls later than the
          // pattern suggests.
          if (_hasGap) ...[
            HeightSpace(6.h),
            _factLine(
              Icons.info_outline,
              _gapText(),
              const Color(0xFF1565C0),
              bold: true,
            ),
          ],
          if (_booking.payOnArrival) ...[
            HeightSpace(6.h),
            _factLine(
              Icons.attach_money,
              'الدفع عند الوصول — لم يُدفع بعد',
              const Color(0xFFB26A00),
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Says plainly that the venue keeps the existing booking AND gains these
  /// four — the gap is not a loss, it is a slot somebody already paid for.
  String _gapText() {
    final skipped = _booking.seriesSkippedDates.map(arabicShortDate).join('، ');

    return skipped.isEmpty
        ? 'يتخطى موعدًا محجوزًا مسبقًا — الحجز القائم يبقى كما هو.'
        : 'يتخطى $skipped (محجوز مسبقًا) — الحجز القائم يبقى كما هو، '
            'وتكسب $_countLabel إضافية.';
  }

  String get _countLabel => '${_booking.seriesOccurrenceCount} مواعيد';

  Widget _factLine(IconData icon, String text, Color color,
      {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: color),
        WidthSpace(6.w),
        Expanded(
          child: Text(
            text,
            style:
                (bold ? AppTextStyles.font12Bold : AppTextStyles.font12Regular)
                    .copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _totalRow() {
    final total = _booking.seriesTotalAmount > 0
        ? _booking.seriesTotalAmount
        : (double.tryParse(_booking.serviceAmount) ?? 0) *
            _booking.seriesOccurrenceCount;

    return Row(
      children: [
        Expanded(
          child: Text(
            'الإجمالي: ${total.toStringAsFixed(0)} دينار',
            style: AppTextStyles.font14Bold.copyWith(color: AppColors.primary),
          ),
        ),
        Text(
          'مراجعة المواعيد',
          style: AppTextStyles.font12Bold.copyWith(color: AppColors.primary),
        ),
        Icon(Icons.chevron_left, size: 18.sp, color: AppColors.primary),
      ],
    );
  }

  /// Accept and refuse on the card itself, so a pending request can be
  /// answered without opening it — while the session list stays one tap away
  /// for anyone who wants to look first.
  Widget _decisionButtons() {
    return Row(
      children: [
        Expanded(
          child: ButtonApp(
            text: _deciding ? 'جاري التنفيذ' : 'رفض',
            textColor: Colors.white,
            backGround: Colors.redAccent,
            onTap: _deciding ? null : () => _decide(_cancelled),
          ),
        ),
        WidthSpace(10.w),
        Expanded(
          child: ButtonApp(
            text: _deciding ? 'جاري التنفيذ' : 'قبول',
            textColor: Colors.white,
            backGround: AppColors.primary,
            onTap: _deciding ? null : () => _decide(_approved),
          ),
        ),
      ],
    );
  }

  Future<void> _decide(int status) async {
    final approving = status == _approved;
    final count = _booking.seriesOccurrenceCount;

    // A second step, because this answers four sessions at once.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          approving ? 'قبول الحجز الشهري؟' : 'رفض الحجز الشهري؟',
          style: AppTextStyles.font16Bold,
        ),
        content: Text(
          approving
              ? 'سيتم قبول $count مواعيد دفعة واحدة، وتصبح الخانات محجوزة.'
              : 'سيتم رفض $count مواعيد دفعة واحدة، وتعود الخانات متاحة.',
          style: AppTextStyles.font14Regular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('تراجع', style: AppTextStyles.font14Bold),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              approving ? 'قبول' : 'رفض',
              style: AppTextStyles.font14Bold.copyWith(
                color: approving ? AppColors.primary : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deciding = true);

    final result = await getIt<BookingRepoImp>().decideManagerSeries(
      seriesId: _booking.seriesId!,
      status: status,
    );

    if (!mounted) return;
    setState(() => _deciding = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.errMessage)),
      ),
      (message) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        widget.onChanged?.call();
      },
    );
  }
}
