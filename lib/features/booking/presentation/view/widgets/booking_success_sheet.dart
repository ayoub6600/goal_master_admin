import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/created_series.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';

/// What the manager chose after a booking was created.
enum BookingSuccessAction { addAnother, backToBookings }

/// The confirmation a manager can read out loud.
///
/// The flow used to drop straight back onto Home, or into a raw HTML viewer,
/// with a toast that was gone before anyone finished reading it — leaving the
/// person who had just taken a booking over the phone with nothing to repeat
/// back to the customer. This states what was booked and offers the two things
/// that actually happen next.
Future<BookingSuccessAction?> showBookingSuccessSheet(
  BuildContext context, {
  required String customerName,
  required String customerPhone,
  required String serviceTitle,
  required BookingOccurrence occurrence,
  required bool isMonthly,
  /// The server's account of a recurring booking. When present it, not the
  /// selected occurrence, is what the screen describes.
  CreatedSeries? series,
}) {
  return showModalBottomSheet<BookingSuccessAction>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 32.w, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                isMonthly ? 'تم تأكيد الحجز الشهري' : 'تم تأكيد الحجز',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.font20Bold.copyWith(color: AppColors.uiBlack),
              ),
              SizedBox(height: 18.h),

              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.inactive3,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _Line(label: 'العميل', value: customerName),
                    _Line(
                      label: 'الهاتف',
                      value: customerPhone,
                      ltr: true,
                    ),
                    _Line(
                      label: 'الخدمة',
                      value: serviceTitle,
                      last: series != null,
                    ),
                    // A recurring booking has four dates and a total; naming
                    // one of them here would be picking an arbitrary week.
                    // They get their own section below.
                    if (series == null) ...[
                      // The start's date, always — the same value that was
                      // submitted, so the manager reads back exactly what the
                      // customer will see.
                      _Line(
                        label: 'التاريخ',
                        value: arabicDayAndDateOf(occurrence.startAt),
                      ),
                      _Line(
                        label: 'الوقت',
                        value:
                            arabicRange(occurrence.startAt, occurrence.endAt),
                      ),
                      if (occurrence.price != null)
                        _Line(
                          label: 'المبلغ',
                          value: '${occurrence.price!.toStringAsFixed(0)} د.ل',
                          last: true,
                        ),
                    ],
                  ],
                ),
              ),

              if (series != null) ...[
                SizedBox(height: 14.h),
                _SeriesOccurrences(series: series),
                SizedBox(height: 12.h),
                _SeriesPayment(series: series),
              ] else if (isMonthly) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(Icons.event_repeat,
                        size: 18.w, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'يتكرر كل ${arabicWeekdayOf(occurrence.startAt)}'
                        ' بنفس التوقيت',
                        style: AppTextStyles.font14Regular
                            .copyWith(color: AppColors.fontColor),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                          sheetContext, BookingSuccessAction.backToBookings),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, 50.h),
                        side: BorderSide(color: AppColors.inactive4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('العودة للحجوزات',
                          style: AppTextStyles.font14Bold
                              .copyWith(color: AppColors.uiBlack)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                          sheetContext, BookingSuccessAction.addAnother),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 50.h),
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('إضافة حجز آخر',
                          style: AppTextStyles.font14Bold
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.ltr = false,
    this.last = false,
  });

  final String label;
  final String value;
  final bool ltr;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62.w,
            child: Text(label,
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: TextAlign.right,
              style:
                  AppTextStyles.font16Bold.copyWith(color: AppColors.uiBlack),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four appointments that now exist, as the server listed them.
class _SeriesOccurrences extends StatelessWidget {
  const _SeriesOccurrences({required this.series});

  final CreatedSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.inactive4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المواعيد',
              style:
                  AppTextStyles.font14SemiBold.copyWith(color: AppColors.fontColor)),
          SizedBox(height: 10.h),
          ...series.occurrences.asMap().entries.map((e) {
            final o = e.value;
            final last = e.key == series.occurrences.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight2,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${e.key + 1}',
                        style: AppTextStyles.font12Regular
                            .copyWith(color: AppColors.primary)),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.startAt != null
                              ? arabicDayAndDateOf(o.startAt!)
                              : o.date,
                          style: AppTextStyles.font14Bold
                              .copyWith(color: AppColors.uiBlack),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          o.startAt != null && o.endAt != null
                              ? arabicRange(o.startAt!, o.endAt!)
                              : '${o.startTime} – ${o.endTime}',
                          style: AppTextStyles.font12Regular
                              .copyWith(color: AppColors.fontColor),
                        ),
                        // Quiet, because by now it is simply the appointment —
                        // not a problem the manager still has to deal with.
                        if (o.isReplacement) ...[
                          SizedBox(height: 2.h),
                          Text('موعد بديل',
                              style: AppTextStyles.font12Regular
                                  .copyWith(color: AppColors.primary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// What the series costs, from the server's own total.
///
/// Count, total, collected and outstanding — all the server's own figures for
/// the series, never one appointment's price multiplied out. For a cash
/// booking «المدفوع» is money the VENUE reports holding; it is recorded for
/// the venue's accounting and is not refundable through the platform.
class _SeriesPayment extends StatelessWidget {
  const _SeriesPayment({required this.series});

  final CreatedSeries series;

  @override
  Widget build(BuildContext context) {
    // Summed by the server across the appointments it created, so a week moved
    // into a differently priced band is already reflected. Never the first
    // appointment's price multiplied out.
    final total = series.totalAmount;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('عدد المواعيد',
                  style: AppTextStyles.font14Regular
                      .copyWith(color: AppColors.fontColor)),
              Text('${series.occurrenceCount}',
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.uiBlack)),
            ],
          ),
          if (series.hasUniformPrice && series.pricePerOccurrence > 0) ...[
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('سعر الموعد',
                    style: AppTextStyles.font14Regular
                        .copyWith(color: AppColors.fontColor)),
                Text('${series.pricePerOccurrence.toStringAsFixed(0)} د.ل',
                    style: AppTextStyles.font14Regular
                        .copyWith(color: AppColors.uiBlack)),
              ],
            ),
          ],
          Divider(color: AppColors.inactive4, height: 18.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي',
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.uiBlack)),
              Text('${total.toStringAsFixed(0)} د.ل',
                  style: AppTextStyles.font18Bold
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المدفوع',
                  style: AppTextStyles.font14Regular
                      .copyWith(color: AppColors.fontColor)),
              Text('${series.paidAmount.toStringAsFixed(0)} د.ل',
                  style: AppTextStyles.font16Bold.copyWith(
                    color: series.paidAmount > 0
                        ? AppColors.success
                        : AppColors.fontColor,
                  )),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المتبقي',
                  style: AppTextStyles.font14Regular
                      .copyWith(color: AppColors.fontColor)),
              Text('${series.remainingAmount.toStringAsFixed(0)} د.ل',
                  style: AppTextStyles.font16Bold.copyWith(
                    color: series.remainingAmount > 0
                        ? AppColors.uiBlack
                        : AppColors.success,
                  )),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('حالة الدفع',
                  style: AppTextStyles.font14Regular
                      .copyWith(color: AppColors.fontColor)),
              Text(series.paymentLabel,
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
