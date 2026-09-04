import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart'
    show SlotTime;

/// Moving a booking to another date or time, driven by real availability.
///
/// The manager never types a date or time by hand here: the slots on offer
/// come from the same operational-availability endpoint the booking screen
/// itself uses, so a chip that is shown is a chip the venue can actually
/// take. Availability is never worked out on the client — the final word
/// belongs to the server, and a slot that looked free when the sheet opened
/// can still be refused on save, in which case nothing is written.
///
/// Deliberately generic: it takes plain dates and a slot loader/confirm
/// callback rather than a booking model, so the same sheet serves both a
/// single booking and one occurrence of a recurring one.
class RescheduleBookingSheet extends StatefulWidget {
  const RescheduleBookingSheet({
    super.key,
    required this.currentStart,
    required this.currentEnd,
    required this.loadSlots,
    required this.onConfirm,
    this.scopeNote,
    this.now,
  });

  final DateTime currentStart;
  final DateTime currentEnd;

  /// The night's slots, from the server.
  final Future<List<OperationalSlot>> Function(String operationalDate)
      loadSlots;

  /// Sends the move. Returns the server's refusal, or null on success.
  final Future<String?> Function(DateTime start, DateTime end) onConfirm;

  /// What this reschedule does and does not affect — e.g. "only this session
  /// of the monthly booking". Omitted for a plain one-off booking.
  final String? scopeNote;

  final DateTime? now;

  static Future<void> show(
    BuildContext context, {
    required DateTime currentStart,
    required DateTime currentEnd,
    required Future<List<OperationalSlot>> Function(String operationalDate)
        loadSlots,
    required Future<String?> Function(DateTime start, DateTime end) onConfirm,
    String? scopeNote,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 12.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: RescheduleBookingSheet(
            currentStart: currentStart,
            currentEnd: currentEnd,
            loadSlots: loadSlots,
            onConfirm: onConfirm,
            scopeNote: scopeNote,
          ),
        ),
      ),
    );
  }

  @override
  State<RescheduleBookingSheet> createState() =>
      _RescheduleBookingSheetState();
}

class _RescheduleBookingSheetState extends State<RescheduleBookingSheet> {
  late DateTime _date;
  OperationalSlot? _chosen;

  List<OperationalSlot>? _slots;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final _dateScroll = ScrollController();

  DateTime get _clock => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.currentStart.year,
      widget.currentStart.month,
      widget.currentStart.day,
    );
    _fetch();

    // Opens on the booking's own date rather than at the start of the range,
    // so the sheet does not read as "pick a date" when nothing has changed
    // yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelectedDate());
  }

  @override
  void dispose() {
    _dateScroll.dispose();
    super.dispose();
  }

  void _revealSelectedDate() {
    if (!_dateScroll.hasClients) return;

    final days = _days();
    final index = days.indexWhere((d) =>
        d.year == _date.year && d.month == _date.month && d.day == _date.day);
    if (index < 0) return;

    final offset = (index * (62.w + 8.w)) - 24.w;
    _dateScroll.jumpTo(
      offset.clamp(0, _dateScroll.position.maxScrollExtent),
    );
  }

  /// A week either side of the booking, never earlier than today.
  List<DateTime> _days() {
    final today = DateTime(_clock.year, _clock.month, _clock.day);
    final base = DateTime(
      widget.currentStart.year,
      widget.currentStart.month,
      widget.currentStart.day,
    );

    return List.generate(15, (i) => base.add(Duration(days: i - 7)))
        .where((d) => !d.isBefore(today))
        .toList();
  }

  String get _dateKey =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-'
      '${_date.day.toString().padLeft(2, '0')}';

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _slots = null;
      _chosen = null;
    });

    try {
      final slots = await widget.loadSlots(_dateKey);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل المواعيد المتاحة.';
        _loading = false;
      });
    }
  }

  /// The slot the booking already occupies is offered even though it reads
  /// as taken — it is taken by this very booking.
  bool _isCurrentSlot(OperationalSlot s) {
    final onCurrentDay = _date.year == widget.currentStart.year &&
        _date.month == widget.currentStart.month &&
        _date.day == widget.currentStart.day;
    return onCurrentDay && s.startAt == widget.currentStart;
  }

  /// The manager picked the slot the booking already occupies — offered so
  /// the current time does not look unavailable, but not a change.
  bool get _isNoChange {
    final chosen = _chosen;
    if (chosen == null) return false;
    return chosen.startAt == widget.currentStart &&
        chosen.endAt == widget.currentEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text('تعديل الموعد', style: AppTextStyles.font18Bold),
        if (widget.scopeNote != null) ...[
          HeightSpace(6.h),
          _scopeBanner(widget.scopeNote!),
        ],
        HeightSpace(14.h),
        _current(),
        HeightSpace(14.h),
        Text('اختر التاريخ', style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        _datePicker(),
        HeightSpace(14.h),
        Text('اختر الوقت', style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        _slotPicker(),
        if (_chosen != null) ...[
          HeightSpace(16.h),
          _isNoChange ? _noChangeNotice() : _summary(),
        ],
        HeightSpace(16.h),
        _confirmButton(),
      ],
    );
  }

  Widget _scopeBanner(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.font12Regular.copyWith(color: AppColors.primary),
      ),
    );
  }

  // ---- What it is now ----------------------------------------------------

  Widget _current() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموعد الحالي',
            style: AppTextStyles.font12Bold.copyWith(color: AppColors.fontColor),
          ),
          HeightSpace(6.h),
          Text(
            '${arabicDayAndDateOf(widget.currentStart)} ${widget.currentStart.year}',
            style: AppTextStyles.font14Bold,
          ),
          HeightSpace(3.h),
          _range(widget.currentStart, widget.currentEnd),
        ],
      ),
    );
  }

  Widget _range(DateTime start, DateTime end, {Color? color}) {
    final style =
        AppTextStyles.font14Regular.copyWith(color: color ?? AppColors.uiBlack);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          SlotTime.rangeText((start.hour, start.minute), (end.hour, end.minute)),
          textDirection: TextDirection.ltr,
          style: style,
        ),
        WidthSpace(4.w),
        Text(arabicDayPeriodOf(start.hour, start.minute), style: style),
      ],
    );
  }

  // ---- Date ---------------------------------------------------------------

  Widget _datePicker() {
    final days = _days();

    return SizedBox(
      // Deliberately unscaled — the chip's text is a fixed point size, so a
      // height scaled by ScreenUtil shrinks on a short screen while its
      // contents do not, overflowing by a pixel or two.
      height: 66,
      child: ListView.separated(
        controller: _dateScroll,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final d = days[i];
          final selected = d.year == _date.year &&
              d.month == _date.month &&
              d.day == _date.day;

          return GestureDetector(
            onTap: () {
              setState(() => _date = d);
              _fetch();
            },
            child: Container(
              width: 62.w,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xffF6F8FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : const Color(0xffE1E6EB),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    arabicWeekdayOf(d),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font10Regular.copyWith(
                      color: selected ? Colors.white : AppColors.fontColor,
                    ),
                  ),
                  HeightSpace(2.h),
                  Text(
                    '${d.day}',
                    style: AppTextStyles.font14Bold.copyWith(
                      color: selected ? Colors.white : AppColors.uiBlack,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Slots ---------------------------------------------------------------

  Widget _slotPicker() {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _notice(_error!, retry: _fetch);
    }

    final free = (_slots ?? const <OperationalSlot>[])
        .where((s) => s.isAvailable || _isCurrentSlot(s))
        .toList();

    if (free.isEmpty) {
      return _notice('لا توجد مواعيد متاحة في هذا اليوم. جرّب تاريخًا آخر.');
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: free.map((s) {
        final selected = _chosen?.startAt == s.startAt;
        final isCurrent = _isCurrentSlot(s);

        return GestureDetector(
          onTap: () => setState(() => _chosen = s),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xffE1E6EB),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _range(
                  s.startAt,
                  s.endAt,
                  color: selected ? Colors.white : AppColors.uiBlack,
                ),
                if (isCurrent) ...[
                  HeightSpace(2.h),
                  Text(
                    'الموعد الحالي',
                    style: AppTextStyles.font10Regular.copyWith(
                      color: selected ? Colors.white : AppColors.fontColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _notice(String text, {VoidCallback? retry}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
          ),
          if (retry != null) ...[
            HeightSpace(8.h),
            GestureDetector(
              onTap: retry,
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.font12Bold.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Before → after -------------------------------------------------------

  Widget _summary() {
    final chosen = _chosen!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموعد الحالي',
            style: AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
          ),
          HeightSpace(3.h),
          Text(
            '${arabicDayAndDateOf(widget.currentStart)} ${widget.currentStart.year}',
            style: AppTextStyles.font14Regular.copyWith(color: AppColors.fontColor),
          ),
          _range(widget.currentStart, widget.currentEnd, color: AppColors.fontColor),
          HeightSpace(9.h),
          Text(
            'سيصبح',
            style: AppTextStyles.font12Bold.copyWith(color: AppColors.primary),
          ),
          HeightSpace(3.h),
          Text(
            '${arabicDayAndDateOf(chosen.startAt)} ${chosen.startAt.year}',
            style: AppTextStyles.font14Bold,
          ),
          _range(chosen.startAt, chosen.endAt),
        ],
      ),
    );
  }

  Widget _noChangeNotice() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16.r, color: AppColors.fontColor),
          WidthSpace(8.w),
          Expanded(
            child: Text(
              'هذا هو الموعد الحالي بالفعل. اختر وقتًا أو تاريخًا آخر لتغييره.',
              style: AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Confirm --------------------------------------------------------------

  Widget _confirmButton() {
    final ready = _chosen != null && !_saving && !_isNoChange;

    return SizedBox(
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
        onPressed: ready ? _confirm : null,
        child: Text(
          _saving ? 'جارٍ الحفظ…' : 'تأكيد التعديل',
          style: AppTextStyles.font16Bold.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final chosen = _chosen!;

    setState(() => _saving = true);
    final refusal = await widget.onConfirm(chosen.startAt, chosen.endAt);
    if (!mounted) return;

    setState(() {
      _saving = false;
      // A refusal leaves the booking exactly where it was; the sheet stays
      // open so the manager can pick a different time instead of losing
      // everything just selected.
      _error = refusal;
    });

    if (refusal == null && mounted) Navigator.of(context).pop();
  }
}
