import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_series.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/reschedule_booking_sheet.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/series_deposit_sheet.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo_imp.dart';

/// Everything the venue needs to decide on a recurring booking.
///
/// The list shows a series as one row on purpose; this is where the four
/// sessions become visible. The decision lives here rather than on the list
/// card, because agreeing to four dates from a summary would be agreeing to
/// something not fully shown.
///
/// One decision covers all sessions — accepting two Thursdays out of four
/// would leave the customer with something nobody offered.
class ManagerSeriesDetails extends StatefulWidget {
  const ManagerSeriesDetails({super.key, required this.seriesId});

  final int seriesId;

  @override
  State<ManagerSeriesDetails> createState() => _ManagerSeriesDetailsState();
}

class _ManagerSeriesDetailsState extends State<ManagerSeriesDetails> {
  late final BookingRepoImp _repo = getIt<BookingRepoImp>();

  ManagerSeries? _series;
  String? _error;
  bool _loading = true;
  bool _deciding = false;

  static const _approved = 2;
  static const _cancelled = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final result = await _repo.getManagerSeries(widget.seriesId);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.errMessage;
        _loading = false;
      }),
      (series) => setState(() {
        _series = series;
        _error = null;
        _loading = false;
      }),
    );
  }

  Future<void> _decide(int status) async {
    final confirmed = await _confirm(status);
    if (confirmed != true) return;

    setState(() => _deciding = true);

    final result = await _repo.decideManagerSeries(
      seriesId: widget.seriesId,
      status: status,
    );

    if (!mounted) return;
    setState(() => _deciding = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.errMessage)),
      ),
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        // Reloaded rather than patched locally, so what is shown is what the
        // server actually recorded.
        _load();
      },
    );
  }

  /// A second step before a decision that covers four sessions at once.
  Future<bool?> _confirm(int status) {
    final approving = status == _approved;
    final count = _series?.pendingCount ?? 0;

    return showDialog<bool>(
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
  }

  String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  /// Takes a payment for the series as a whole.
  ///
  /// The amount goes to the server against the series, not against a session:
  /// which weeks it settles is decided there, earliest first, in one
  /// transaction. Entering it session by session meant the manager had to do
  /// that split by hand, and a payment covering two and a half weeks had no
  /// honest way to be recorded at all.
  Future<void> _recordDeposit(ManagerSeries series) async {
    final amount = await SeriesDepositSheet.show(context, series);
    if (amount == null || !mounted) return;

    setState(() => _deciding = true);

    final result = await _repo.depositManagerSeries(
      seriesId: series.seriesId,
      amount: amount,
    );

    if (!mounted) return;
    setState(() => _deciding = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.errMessage)),
      ),
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        // Reloaded rather than patched locally: the server caps an
        // overpayment at what is outstanding, so what it recorded is not
        // necessarily what was typed.
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'تفاصيل الحجز الشهري',
      allowBack: true,
      child: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.font14Regular.copyWith(color: Colors.redAccent),
          ),
        ),
      );
    }

    final series = _series!;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summary(series),
              HeightSpace(18.h),
              Row(
                children: [
                  Text('المواعيد', style: AppTextStyles.font16Bold),
                  WidthSpace(8.w),
                  Text(
                    '(${series.occurrences.length})',
                    style: AppTextStyles.font14Regular
                        .copyWith(color: AppColors.fontColor),
                  ),
                ],
              ),
              HeightSpace(10.h),
              ...series.occurrences.map(_occurrenceCard),
              if (series.awaitingDecision) ...[
                HeightSpace(20.h),
                _decisionButtons(),
              ]
              // An ACTIVE series can only be called off as a whole. Doing it
              // session by session sent the customer a message for each,
              // every one promising the rest were still booked.
              else if (series.occurrences.any((o) => o.isApproved)) ...[
                HeightSpace(20.h),
                _cancelSeriesButton(series),
              ],
            ],
          ),
        ),
        if (_deciding)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _summary(ManagerSeries series) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat, size: 20.sp, color: AppColors.primary),
              WidthSpace(8.w),
              Text('حجز شهري', style: AppTextStyles.font16Bold),
              const Spacer(),
              if (series.awaitingDecision)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'بانتظار قرارك',
                    style: AppTextStyles.font12Bold
                        .copyWith(color: const Color(0xFFB26A00)),
                  ),
                ),
            ],
          ),
          HeightSpace(12.h),
          _line(Icons.person, series.customer),
          if (series.customerPhoneNo.isNotEmpty)
            _line(Icons.phone, series.customerPhoneNo, ltr: true),
          _line(
            Icons.schedule,
            'كل ${series.dayName} — ${arabicTime(series.startTime)} '
            'إلى ${arabicTime(series.endTime)}',
          ),
          _line(
            Icons.calendar_month,
            'من ${arabicShortDate(series.startsOn)} '
            'إلى ${arabicDateWithYear(series.endsOn)}',
          ),
          // Shown before the decision: the four sessions are not four
          // consecutive weeks, and the existing booking in the gap stays
          // exactly as it is.
          if (series.skippedCount > 0) _skippedNotice(series),
          HeightSpace(10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${series.occurrenceCount} × ${series.pricePerOccurrence.toStringAsFixed(0)} دينار',
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.fontColor),
                    ),
                    const Spacer(),
                    Text(
                      '${series.totalAmount.toStringAsFixed(0)} دينار',
                      style: AppTextStyles.font16Bold
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                if (series.payOnArrival) ...[
                  HeightSpace(8.h),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 16.sp, color: const Color(0xFFB26A00)),
                      WidthSpace(6.w),
                      Expanded(
                        child: Text(
                          'الدفع عند الوصول — المبلغ يُحصَّل في الملعب',
                          style: AppTextStyles.font12Bold
                              .copyWith(color: const Color(0xFFB26A00)),
                        ),
                      ),
                    ],
                  ),
                ],
                // The money actually collected against the series, and the way
                // to add to it. A monthly booking is paid a bit at a time, and
                // entering that per session meant deciding by hand which weeks
                // each payment covered.
                if (series.grossTotal > 0) ...[
                  HeightSpace(10.h),
                  Divider(height: 1, color: const Color(0xFFE1E6EB)),
                  HeightSpace(10.h),
                  Row(
                    children: [
                      Text(
                        'المدفوع: ${_money(series.paidTotal)} دينار',
                        style: AppTextStyles.font12Bold
                            .copyWith(color: AppColors.primary),
                      ),
                      const Spacer(),
                      if (series.remainingTotal > 0)
                        Text(
                          'المتبقي: ${_money(series.remainingTotal)} دينار',
                          style: AppTextStyles.font12Bold
                              .copyWith(color: const Color(0xFFB26A00)),
                        )
                      else
                        Text(
                          'مدفوع بالكامل ✓',
                          style: AppTextStyles.font12Bold
                              .copyWith(color: AppColors.primary),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Only once the series is actually agreed: money taken against
          // sessions the venue has not accepted would have to be given back.
          if (series.remainingTotal > 0 && !series.awaitingDecision) ...[
            HeightSpace(12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _deciding ? null : () => _recordDeposit(series),
                icon: Icon(Icons.payments_outlined,
                    size: 18.sp, color: Colors.white),
                label: Text(
                  'تسجيل دفعة',
                  style:
                      AppTextStyles.font14Bold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Why there is a gap, and what the venue keeps because of it.
  Widget _skippedNotice(ManagerSeries series) {
    final dates = series.skippedDates.map(arabicShortDate).join('، ');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 6.h, bottom: 4.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.07),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16.sp, color: const Color(0xFF1565C0)),
          WidthSpace(8.w),
          Expanded(
            child: Text(
              dates.isEmpty
                  ? 'هذا الحجز يتخطى موعدًا محجوزًا مسبقًا. الحجز القائم يبقى كما هو.'
                  : 'هذا الحجز يتخطى $dates لأنه محجوز مسبقًا. '
                      'الحجز القائم يبقى كما هو، ويمكنك قبول هذه '
                      '${series.occurrenceCount} مواعيد رغم ذلك.',
              style: AppTextStyles.font12Bold
                  .copyWith(color: const Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, {bool ltr = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.fontColor),
          WidthSpace(8.w),
          Expanded(
            child: Text(
              text,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: ltr ? TextAlign.right : null,
              style: AppTextStyles.font14Medium,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the full booking screen for one session of the series.
  ///
  /// Every session is a booking in its own right, with its own payment and its
  /// own cancel/edit actions — this screen only ever summarised them. The
  /// series is reloaded on the way back so a payment taken over there shows
  /// here without the manager having to reopen the series.
  Future<void> _openOccurrence(SeriesOccurrence occurrence) async {
    await push(
      RoutesKeys.kBookingItemsDetails,
      context,
      extra: occurrence.bookingId,
    );

    if (!mounted) return;
    _load();
  }

  Future<void> _editOccurrence(SeriesOccurrence occurrence) async {
    // The occurrence carries only what the series list needs. Branch,
    // employee, service and payment-type ids only come back from the full
    // booking record, so it is fetched fresh before the sheet can open.
    final detailsResult = await _repo.getBookingInfo(occurrence.bookingId);

    if (!mounted) return;

    await detailsResult.fold(
      (failure) async => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.errMessage)),
      ),
      (booking) async {
        final start = DateTime(
          booking.date.year,
          booking.date.month,
          booking.date.day,
          int.tryParse(booking.startTime.split(':')[0]) ?? 0,
          int.tryParse(booking.startTime.split(':')[1]) ?? 0,
        );
        final endParts = booking.endTime.split(':');
        final end = DateTime(
          booking.date.year,
          booking.date.month,
          booking.date.day,
          int.tryParse(endParts[0]) ?? 0,
          int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0,
        );

        final monthlyRepo = getIt<MonthlyBookingRepoImp>();

        await RescheduleBookingSheet.show(
          context,
          currentStart: start,
          currentEnd: end,
          scopeNote: 'أنت تعدّل هذا الموعد فقط. بقية مواعيد الحجز الشهري '
              'لن تتغيّر.',
          loadSlots: (operationalDate) async {
            final result = await _repo.listNightSlots(
              branchId: booking.branchId,
              serviceId: booking.serviceId,
              operationalDate: operationalDate,
            );

            return result.fold(
              (failure) => throw Exception(failure.errMessage),
              (night) => night.slots,
            );
          },
          onConfirm: (newStart, newEnd) async {
            String two(int v) => v.toString().padLeft(2, '0');

            final result = await monthlyRepo.rescheduleOccurrence(
              bookingId: booking.id,
              branchId: booking.branchId,
              customerId: booking.cmnCustomerId,
              employeeId: booking.employeeId,
              serviceId: booking.serviceId,
              paymentTypeId: booking.paymentTypeId,
              status: booking.status,
              paidAmount: double.tryParse(booking.paidAmount) ?? 0,
              serviceDate:
                  '${newStart.year}-${two(newStart.month)}-${two(newStart.day)}',
              serviceTime:
                  '${two(newStart.hour)}:${two(newStart.minute)}-'
                  '${two(newEnd.hour)}:${two(newEnd.minute)}',
              remarks: booking.remarks,
            );

            return result.fold(
              (failure) => failure.errMessage,
              (_) {
                showCustomSuccessToast('تم تعديل الموعد.');
                _load();
                return null;
              },
            );
          },
        );
      },
    );
  }

  /// One session. Numbered, so "the third of four" is readable at a glance,
  /// and tappable, because each one is a booking with a screen of its own.
  Widget _occurrenceCard(SeriesOccurrence occurrence) {
    final (color, label, icon) = switch (occurrence) {
      SeriesOccurrence(isCancelled: true) => (
          Colors.redAccent,
          'ملغي',
          Icons.cancel_outlined
        ),
      SeriesOccurrence(isDone: true) => (
          AppColors.primary,
          'تم',
          Icons.check_circle_outline
        ),
      SeriesOccurrence(isApproved: true) => (
          AppColors.primary,
          'مقبول',
          Icons.event_available
        ),
      _ => (const Color(0xFFB26A00), 'بانتظار القرار', Icons.hourglass_empty),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () => _openOccurrence(occurrence),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${occurrence.sequence}',
                    style: AppTextStyles.font14Bold.copyWith(color: color),
                  ),
                ),
                WidthSpace(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              arabicDayAndDate(occurrence.date),
                              style: AppTextStyles.font14Bold,
                            ),
                          ),
                          WidthSpace(6.w),
                          // The booking number, so a session can be matched
                          // against a receipt or a phone call without opening
                          // it first.
                          Text(
                            '#${occurrence.bookingId}',
                            style: AppTextStyles.font12Bold
                                .copyWith(color: AppColors.fontColor),
                          ),
                        ],
                      ),
                      Text(
                        '${arabicTime(occurrence.startTime)} - '
                        '${arabicTime(occurrence.endTime)}',
                        style: AppTextStyles.font12Regular
                            .copyWith(color: AppColors.fontColor),
                      ),
                      // Where this session stands on money, separately from
                      // where it stands in its life. A part-paid series is the
                      // earliest weeks settled and the next one partly so, and
                      // only a per-session line can say that.
                      if (!occurrence.isCancelled) ...[
                        HeightSpace(4.h),
                        _paymentChip(occurrence),
                      ],
                      // The date above is the one actually booked. This only
                      // says why this week sits off the pattern, so a venue
                      // does not read it as a mistake.
                      if (occurrence.isReplacement) ...[
                        HeightSpace(3.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            occurrence.replacementNote.isNotEmpty
                                ? occurrence.replacementNote
                                : 'موعد بديل ضمن حجز شهري',
                            style: AppTextStyles.font12Bold
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16.sp, color: color),
                        WidthSpace(4.w),
                        Text(
                          label,
                          style:
                              AppTextStyles.font12Bold.copyWith(color: color),
                        ),
                      ],
                    ),
                    HeightSpace(4.h),
                    Row(
                      children: [
                        if (occurrence.isApproved &&
                            !occurrence.hasElapsed) ...[
                          InkWell(
                            onTap: () => _editOccurrence(occurrence),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 15.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          WidthSpace(4.w),
                        ],
                        Text(
                          'التفاصيل',
                          style: AppTextStyles.font12Regular
                              .copyWith(color: AppColors.fontColor),
                        ),
                        Icon(
                          Icons.chevron_left,
                          size: 15.sp,
                          color: AppColors.fontColor,
                        ),
                      ],
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

  /// How much of this one session has been collected.
  ///
  /// Says the amounts on a partial payment rather than only the word: «مدفوع
  /// جزئي» alone leaves the manager reopening the booking to find out how much
  /// is still owed on the week they are looking at.
  Widget _paymentChip(SeriesOccurrence occurrence) {
    final (color, label) = switch (occurrence) {
      SeriesOccurrence(isPaid: true) => (AppColors.primary, 'خالص'),
      SeriesOccurrence(isPartiallyPaid: true) => (
          const Color(0xFFB26A00),
          'مدفوع جزئي — ${_money(occurrence.paidAmount)} من '
              '${_money(occurrence.serviceAmount)} د',
        ),
      _ => (AppColors.fontColor, 'غير مدفوع'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12Bold.copyWith(color: color),
      ),
    );
  }

  /// Calls off the whole monthly booking, in one action and one message.
  Widget _cancelSeriesButton(ManagerSeries series) {
    final remaining = series.occurrences.where((o) => o.isApproved).length;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: EdgeInsets.symmetric(vertical: 13.h),
        ),
        onPressed:
            _deciding ? null : () => _cancelWholeSeries(series, remaining),
        child: const Text('إلغاء الحجز الشهري بالكامل',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _cancelWholeSeries(ManagerSeries series, int remaining) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('إلغاء الحجز الشهري بالكامل؟',
            style: AppTextStyles.font16Bold),
        content: Text(
          'سيتم إلغاء $remaining مواعيد متبقية، ويصل الزبون إشعار واحد '
          'يوضح أن الحجز الشهري أُلغي بالكامل.',
          style: AppTextStyles.font14Regular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('تراجع', style: AppTextStyles.font14Bold),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('إلغاء بالكامل',
                style:
                    AppTextStyles.font14Bold.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deciding = true);

    final result =
        await getIt<BookingRepoImp>().cancelManagerSeries(series.seriesId);

    if (!mounted) return;
    setState(() => _deciding = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.errMessage))),
      (message) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        _load();
      },
    );
  }

  Widget _decisionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => _decide(_cancelled),
            child: Text(
              'رفض الكل',
              style: AppTextStyles.font14Bold.copyWith(color: Colors.redAccent),
            ),
          ),
        ),
        WidthSpace(12.w),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => _decide(_approved),
            child: Text(
              'قبول الكل',
              style: AppTextStyles.font14Bold.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
