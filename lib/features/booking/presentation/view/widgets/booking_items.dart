import 'package:flutter/material.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/attendance_actions_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:intl/intl.dart';

import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';

class BookingItems extends StatefulWidget {
  const BookingItems({super.key, required this.booking});
  final BookingItemResponce booking;

  @override
  State<BookingItems> createState() => _BookingItemsState();
}

class _BookingItemsState extends State<BookingItems> {
  bool _isUpdating = false;

  BookingItemResponce get booking => widget.booking;

  /// Whether this booking's slot has already finished.
  ///
  /// Compared in wall-clock, the same frame the booking was written in —
  /// deriving it from a UTC-serialised timestamp is what once showed
  /// Saturday for a Sunday booking.
  Future<void> _updateStatus(BuildContext context, String status) async {
    setState(() => _isUpdating = true);

    final result =
        await getIt<BookingRepoImp>().updateStatusBooking(booking.id, status);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    result.fold(
      (failure) => showCustomFailureToast(failure.errMessage),
      (message) {
        CustomSuccessToast(toastText: message);
        final bookingState = context.read<BookingCubit>().state;
        if (bookingState is BookingSuccess) {
          bookingState.pagingController.refresh();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        push(RoutesKeys.kBookingItemsDetails, context, extra: booking.id);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(vertical: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primary,
          ),
        ),
        child: Column(
          children: [
            HeightSpace(6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "# رقم الحجز : ",
                        style: AppTextStyles.font16Bold.copyWith(
                          color: AppColors.fontColor,
                        ),
                      ),
                      WidthSpace(10.w),
                      Text(
                        booking.id.toString(),
                        style: AppTextStyles.font16Bold.copyWith(
                          color: AppColors.fontColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "( ${booking.paymentStatusName} )",
                    style: AppTextStyles.font16Bold.copyWith(
                      color: _getPaymentStatusColor(booking.paymentStatus),
                    ),
                  ),
                ],
              ),
            ),
            HeightSpace(10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 7.w),
                  padding:
                      EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0xffDFF5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      WidthSpace(10.w),
                      Text(
                        booking.service,
                        style: AppTextStyles.font16Bold.copyWith(
                          color: const Color(0xff204523),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 18.h,
                    horizontal: 30.w,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffDFF5E1),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.r),
                      bottomRight: Radius.circular(12.r),
                    ),
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0xffDFF5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        booking.branch,
                        style: AppTextStyles.font16Bold.copyWith(
                          color: const Color(0xff204523),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            HeightSpace(16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Image.asset(
                    Assets.imagesPngImageProfailIcon,
                    fit: BoxFit.cover,
                  ),
                  WidthSpace(10.w),
                  Text(
                    booking.customer,
                    style: AppTextStyles.font16Bold.copyWith(
                      color: AppColors.fontColor,
                    ),
                  ),
                ],
              ),
            ),
            HeightSpace(16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          Assets.imagesPngImageClock,
                          fit: BoxFit.cover,
                        ),
                        WidthSpace(10.w),
                        Text(
                          formatTimeFromDate(booking.startTime),
                          style: AppTextStyles.font16Bold.copyWith(
                            color: AppColors.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          Assets.imagesPngImageCalendar,
                          fit: BoxFit.cover,
                        ),
                        WidthSpace(10.w),
                        Text(
                          formatDateFromDate(booking.date),
                          style: AppTextStyles.font16Bold.copyWith(
                            color: AppColors.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            HeightSpace(16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: AppTextStyles.font12Regular.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    "السعر : ${booking.serviceAmount} دينار",
                    style: AppTextStyles.font18Bold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (booking.status == 3 && booking.cancellation != null) ...[
              HeightSpace(12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: _CancellationOutcomeBox(
                  cancellation: booking.cancellation!,
                ),
              ),
            ],
            if (booking.paymentType == 1) ...[
              HeightSpace(8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'العميل يريد الدفع عند الوصول',
                  style: AppTextStyles.font14Regular
                      .copyWith(color: Colors.orange[800]),
                ),
              ),
            ],
            if (booking.status == 1) ...[
              HeightSpace(12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  children: [
                    Expanded(
                      child: ButtonApp(
                        text: _isUpdating ? "جاري التنفيذ" : "رفض",
                        textColor: Colors.white,
                        backGround: Colors.red,
                        onTap: _isUpdating
                            ? null
                            : () => _updateStatus(context, '3'),
                      ),
                    ),
                    WidthSpace(12.w),
                    Expanded(
                      child: ButtonApp(
                        text: _isUpdating ? "جاري التنفيذ" : "قبول",
                        textColor: Colors.white,
                        backGround: AppColors.primary,
                        onTap: _isUpdating
                            ? null
                            : () => _updateStatus(context, '2'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // An approved booking whose slot has finished still needs an
            // answer: settlement waits on it, and silence eventually settles
            // it anyway. Offered here so the venue never has to hunt for it.
            //
            // The SERVER decides when that moment arrives. This used to be
            // worked out here from displayEndTime — which the booking-list
            // endpoint never sent for a normal booking — so it fell back to
            // "ends 23:59" and withheld the button for two hours after the
            // slot actually ended. A client holding its own opinion about when
            // money becomes reportable is the bug, not the arithmetic.
            if (booking.canReportAttendance) ...[
              HeightSpace(12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: _ReportOutcomeAction(
                  onTap: () async {
                    final changed = await AttendanceActionsSheet.show(
                      context,
                      booking.id,
                      payOnArrival: booking.paymentType == 1,
                    );

                    if (changed == true && context.mounted) {
                      context.read<BookingCubit>().filterBooking();
                    }
                  },
                ),
              ),
            ],

            // Already answered. The result is shown, and there is no way back
            // to the sheet: a venue that could switch «لم يحضر» to «تم اللعب»
            // after the customer contested it would be marking its own
            // homework. The backend refuses the change too — this is not the
            // only guard, just the honest UI for it.
            if (!booking.canReportAttendance && booking.hasRecordedResult) ...[
              HeightSpace(12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: _RecordedResult(booking: booking),
              ),
            ],
            HeightSpace(12.h),
          ],
        ),
      ),
    );
  }

  String formatTimeFromDate(DateTime time) {
    return DateFormat.jm('ar').format(time); // "8:00 م"
  }

  String formatDateFromDate(DateTime date) {
    return DateFormat.yMMMMd('ar').format(date);
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return "غير خالص";
      case 1:
        return "في الانتظار";
      case 2:
        return 'موافَق عليه';
      case 3:
        return 'ملغي';
      case 4:
        return 'خالص';
      default:
        return 'غير معروف';
    }
  }

  Color _getPaymentStatusColor(int paymentStatus) {
    switch (paymentStatus) {
      case 1:
        return Colors.green; // خالص
      case 3:
        return Colors.orange; // دفع جزئي
      case 2:
      default:
        return Colors.red; // غير مدفوع
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// What a cancelled booking's money actually did, from the venue's side.
///
/// A full refund reads as one calm line — nothing was kept, nothing to
/// explain. A booking that retained a fee is called out: what the venue
/// keeps gets the visual weight, since that is the number a manager checks
/// this card to confirm.
class _CancellationOutcomeBox extends StatelessWidget {
  const _CancellationOutcomeBox({required this.cancellation});

  final BookingCancellation cancellation;

  @override
  Widget build(BuildContext context) {
    if (!cancellation.hasPenalty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xffDFF5E1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18.sp, color: AppColors.primary),
            WidthSpace(8.w),
            Expanded(
              child: Text(
                "إلغاء مجاني — تم استرجاع ${_money(cancellation.refundAmount)} دينار كاملة للزبون",
                style: AppTextStyles.font14Bold.copyWith(
                  color: const Color(0xff204523),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18.sp, color: Colors.red),
              WidthSpace(8.w),
              Text(
                "تفاصيل الإلغاء",
                style: AppTextStyles.font14Bold.copyWith(color: Colors.red),
              ),
            ],
          ),
          HeightSpace(8.h),
          _outcomeRow(
            "استُرجع للزبون",
            cancellation.refundAmount,
            AppColors.primary,
          ),
          HeightSpace(4.h),
          _outcomeRow(
            "المحتفَظ به لديك",
            cancellation.retainedAmount,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _outcomeRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.font14Regular.copyWith(
            color: AppColors.fontColor,
          ),
        ),
        Text(
          "${_money(amount)} د.ل",
          style: AppTextStyles.font14Bold.copyWith(color: color),
        ),
      ],
    );
  }

  String _money(double amount) => amount.toStringAsFixed(2);
}

/// The final, non-editable result of a booking.
///
/// A no-show additionally shows where the customer's answer stands — pending,
/// confirmed, or contested. That is information, not another decision: the
/// venue's report is fixed whatever the customer says.
class _RecordedResult extends StatelessWidget {
  const _RecordedResult({required this.booking});

  final BookingItemResponce booking;

  @override
  Widget build(BuildContext context) {
    final (icon, colour) = switch (booking.attendanceStatus) {
      'attended' => ('✓', const Color(0xFF2E7D32)),
      'no_show' => ('🚫', const Color(0xFFBA4A00)),
      'venue_issue' => ('⚠️', const Color(0xFF1565C0)),
      _ => ('•', AppColors.fontColor),
    };

    // What the customer has said, if anything. Information only — the venue's
    // own report is fixed either way.
    final pending = switch (booking.attendanceStatus) {
      'no_show' => switch (booking.customerConfirmation) {
          'pending' => 'بانتظار تأكيد الزبون',
          'did_not_attend' => 'الزبون أكّد عدم الحضور',
          'attended' => 'الزبون اعترض وقال إنه حضر',
          _ => null,
        },
      'venue_issue' => switch (booking.customerConfirmation) {
          'pending' => 'بانتظار تأكيد الزبون',
          'venue_fault_confirmed' => 'تم تأكيد المشكلة من الزبون',
          'venue_fault_disputed' => 'اعترض الزبون على السبب المسجل',
          _ => null,
        },
      _ => null,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
        color: colour.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon تم تسجيل: ${booking.attendanceStatus == 'venue_issue' ? 'تعذّر اللعب بسبب الملعب' : booking.attendanceLabel}',
            style: AppTextStyles.font14Bold.copyWith(color: colour),
          ),
          if (booking.venueFaultReasonLabel.isNotEmpty) ...[
            HeightSpace(2.h),
            Text(
              'السبب المسجل: ${booking.venueFaultReasonLabel}',
              style: AppTextStyles.font12Regular
                  .copyWith(color: AppColors.fontColor),
            ),
          ],
          if (pending != null) ...[
            HeightSpace(2.h),
            Text(
              pending,
              style: AppTextStyles.font12Regular
                  .copyWith(color: AppColors.fontColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// The venue's answer to "what happened at this booking?".
///
/// This was a solid green ButtonApp, which was wrong twice over. Green on this
/// card already means «موافَق عليه» — a positive status — so a green button
/// pre-answered a question with three answers, one of which is «الزبون لم
/// يحضر». And a filled primary button is the shape of a commit action, while
/// this one only opens a sheet where the real choice is made.
///
/// So: the app's navy rather than any status colour, an icon that says
/// "record an outcome", and a chevron that says "this opens something". It
/// stays prominent because the money waits on it — a venue that skips this
/// does not get paid.
class _ReportOutcomeAction extends StatelessWidget {
  const _ReportOutcomeAction({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    size: 18.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تسجيل نتيجة الحجز',
                        style: AppTextStyles.font16Bold
                            .copyWith(color: Colors.white),
                      ),
                      SizedBox(height: 2.h),
                      // The consequence, which appears nowhere else on the
                      // card: «تم اللعب» is what moves the money.
                      Text(
                        'سجّل ما حدث ليُغلق الحجز ويُصرف المبلغ',
                        style: AppTextStyles.font12Regular.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  size: 20.w,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
