import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';

/// What happened at the pitch.
///
/// Three plain answers, in the venue's own words rather than database states.
/// «تم اللعب» settles the money; «الزبون لم يحضر» records a wasted slot WITHOUT
/// cancelling the booking — a cancellation would refund the customer for a
/// pitch the venue lost, and erase the evidence that it happened; «تعذّر اللعب
/// بسبب الملعب» says the venue could not deliver, which earns no commission and
/// puts no no-show on the customer.
///
/// «مشكلة من الزبون» is deliberately NOT offered. A customer who arrives and
/// then leaves has still consumed the slot, so its money is not a no-show's —
/// that case needs designing before it gets a button.
///
/// One answer only. Once a result is submitted the venue cannot change it; a
/// correction is a dispute, and the backend refuses a second, different report.
class AttendanceActionsSheet extends StatefulWidget {
  const AttendanceActionsSheet({
    super.key,
    required this.bookingId,
    this.payOnArrival = false,
    this.scopeNote,
  });

  final int bookingId;
  final bool payOnArrival;

  /// Which booking this report belongs to, when that is not obvious.
  ///
  /// Empty for an ordinary booking — the manager opened one card and is
  /// reporting on it. Set from the monthly screen, where the session is one
  /// week of four and «هذا الحجز» could reasonably be read as the whole month.
  final String? scopeNote;

  static Future<bool?> show(
    BuildContext context,
    int bookingId, {
    bool payOnArrival = false,
    String? scopeNote,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AttendanceActionsSheet(
        bookingId: bookingId,
        payOnArrival: payOnArrival,
        scopeNote: scopeNote,
      ),
    );
  }

  @override
  State<AttendanceActionsSheet> createState() => _AttendanceActionsSheetState();
}

class _AttendanceActionsSheetState extends State<AttendanceActionsSheet> {
  bool _working = false;
  bool _recordedNoShow = false;
  /// Non-null once «تعذّر اللعب بسبب الملعب» is chosen: the sheet is on its
  /// reason step and has NOT submitted anything yet.
  bool _askingVenueReason = false;
  String? _venueReason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _mark(String status, {String? reasonCode}) async {
    setState(() => _working = true);

    final typed = _noteController.text.trim();

    final result = await getIt<BookingRepoImp>().markAttendance(
      bookingId: widget.bookingId,
      attendanceStatus: status,
      // Free text stays free text; the structured reason travels separately.
      note: typed.isEmpty ? null : typed,
      venueFaultReason: reasonCode,
    );

    if (!mounted) return;
    setState(() => _working = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.errMessage)));
        // A refusal is usually "already recorded" — the card must refresh so
        // it stops offering an action the server will not accept.
        Navigator.of(context).pop(true);
      },
      (message) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));

        // A pay-on-arrival no-show is the one case where the venue has a
        // further decision to make, so the sheet stays open to offer it.
        if (status == 'no_show' && widget.payOnArrival) {
          setState(() => _recordedNoShow = true);
        } else {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  Future<void> _restrict() async {
    setState(() => _working = true);

    final result = await getIt<BookingRepoImp>().restrictPayOnArrival(
      bookingId: widget.bookingId,
      days: 30,
    );

    if (!mounted) return;
    setState(() => _working = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.errMessage))),
      (message) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
      child: _recordedNoShow
          ? _restrictBody()
          : (_askingVenueReason ? _venueReasonBody() : _actionsBody()),
    );
  }

  Widget _actionsBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ما نتيجة هذا الحجز؟',
            textAlign: TextAlign.center, style: AppTextStyles.font16Bold),
        HeightSpace(4.h),
        Text(
          'اختر نتيجة واحدة. بعد التسجيل ما ينفعش تتغيّر.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
        ),
        if (widget.scopeNote != null && widget.scopeNote!.isNotEmpty) ...[
          HeightSpace(12.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.inactive3,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15.r, color: AppColors.dark2),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    widget.scopeNote!,
                    style: AppTextStyles.font12Regular
                        .copyWith(color: AppColors.dark5),
                  ),
                ),
              ],
            ),
          ),
        ],
        HeightSpace(16.h),
        _action('✅ تم اللعب', 'attended', AppColors.primary,
            'يُصرف المبلغ لمحفظتك.'),
        _action('🚫 الزبون لم يحضر', 'no_show', const Color(0xFFBA4A00),
            'الحجز ما يتلغاش — نسجل فقط أن الزبون ما حضرش، ونسأله.'),
        _action('⚠️ تعذّر اللعب بسبب الملعب', 'venue_issue',
            const Color(0xFF1565C0),
            'ما ينحسبش على الزبون، وما فيش عمولة على هذا الحجز.'),
        HeightSpace(10.h),
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(false),
          child: const Text('لاحقاً'),
        ),
      ],
    );
  }

  /// Why the pitch could not be used.
  ///
  /// Asked ONLY for the venue-fault answer, and only after it is chosen, so
  /// «تم اللعب» and «الزبون لم يحضر» stay a single tap. The reason is written
  /// into the report's note, which is what makes a venue-caused failure
  /// auditable later rather than just an absent commission.
  Widget _venueReasonBody() {
    // Code first, label second. The code is what the server counts.
    const reasons = <(String, String)>[
      ('electricity', 'انقطاع الكهرباء'),
      ('pitch_failure', 'عطل في الملعب'),
      ('unavailable', 'الملعب غير متاح'),
      ('emergency', 'إغلاق أو ظرف طارئ'),
      ('other', 'سبب آخر'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('شنو السبب؟',
            textAlign: TextAlign.center, style: AppTextStyles.font16Bold),
        HeightSpace(4.h),
        Text(
          'يساعدنا نتابع المشكلة ونحسبها على الملعب مش على الزبون. حنسأل الزبون يأكد.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
        ),
        HeightSpace(14.h),
        for (final (code, label) in reasons)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: InkWell(
              onTap: _working ? null : () => setState(() => _venueReason = code),
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: _venueReason == code
                        ? const Color(0xFF1565C0)
                        : AppColors.fontColor.withValues(alpha: 0.25),
                    width: _venueReason == code ? 2 : 1,
                  ),
                ),
                child: Text(label, style: AppTextStyles.font14Bold),
              ),
            ),
          ),
        if (_venueReason == 'other') ...[
          HeightSpace(4.h),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'اكتب السبب باختصار',
              hintStyle: AppTextStyles.font12Regular,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
        ],
        HeightSpace(12.h),
        ElevatedButton(
          onPressed: _working || _venueReason == null
              ? null
              : () => _mark('venue_issue', reasonCode: _venueReason),
          child: Text(_working ? 'جاري التسجيل...' : 'تسجيل النتيجة'),
        ),
        TextButton(
          onPressed: _working ? null : () => setState(() => _venueReason = null),
          child: const Text('رجوع'),
        ),
      ],
    );
  }

  Widget _action(String label, String status, Color colour, String hint) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: _working
            ? null
            : () {
                // The venue-fault answer asks one more question before it is
                // recorded; the other two are a single tap, as before.
                if (status == 'venue_issue') {
                  setState(() => _askingVenueReason = true);
                  return;
                }
                _mark(status);
              },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: colour.withValues(alpha: 0.4)),
            color: colour.withValues(alpha: 0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.font14Bold.copyWith(color: colour)),
              HeightSpace(2.h),
              Text(hint,
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.fontColor)),
            ],
          ),
        ),
      ),
    );
  }

  /// Offered only after a pay-on-arrival no-show, and only for this venue.
  Widget _restrictBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('تم تسجيل عدم الحضور',
            textAlign: TextAlign.center, style: AppTextStyles.font16Bold),
        HeightSpace(8.h),
        Text(
          'هذا الحجز كان بالدفع عند الوصول، فما فيش مبلغ محتجز نخصم منه.\n'
          'تقدر تمنع الدفع عند الوصول لهذا الزبون في ملعبك لمدة شهر — '
          'ويبقى قادر يحجز عندك بالدفع المسبق.',
          textAlign: TextAlign.center,
          style: AppTextStyles.font12Regular
              .copyWith(color: AppColors.fontColor, height: 1.5),
        ),
        HeightSpace(16.h),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA4A00)),
          onPressed: _working ? null : _restrict,
          child: const Text('منع الدفع عند الوصول (30 يوم)',
              style: TextStyle(color: Colors.white)),
        ),
        HeightSpace(8.h),
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(true),
          child: const Text('لا، اكتفي بالتسجيل'),
        ),
      ],
    );
  }
}
