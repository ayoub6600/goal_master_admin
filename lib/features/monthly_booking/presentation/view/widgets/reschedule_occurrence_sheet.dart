import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_actions.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';

/// Moving ONE session of a recurring booking to another slot.
///
/// The customer rings and asks for next week only at nine instead of eight.
/// That is a change to one occurrence, and the sheet is built so a manager
/// cannot mistake it for anything wider: the scope is stated before any
/// control is offered, and again in the summary before the change is sent.
///
/// Availability is never worked out here. The slots come from the same
/// operational-availability endpoint the booking screen uses, and the final
/// word belongs to the server — a slot that looked free when the sheet opened
/// is refused on save, and nothing is written.
class RescheduleOccurrenceSheet extends StatefulWidget {
  const RescheduleOccurrenceSheet({
    super.key,
    required this.group,
    required this.occurrence,
    required this.loadSlots,
    required this.onConfirm,
    this.now,
  });

  final MonthlySeriesGroup group;
  final MonthlyBookingResponse occurrence;

  /// The night's slots, from the server.
  final Future<List<OperationalSlot>> Function(String operationalDate)
      loadSlots;

  /// Sends the move. Returns the server's refusal, or null on success.
  final Future<String?> Function(DateTime start, DateTime end) onConfirm;

  final DateTime? now;

  @override
  State<RescheduleOccurrenceSheet> createState() =>
      _RescheduleOccurrenceSheetState();
}

class _RescheduleOccurrenceSheetState extends State<RescheduleOccurrenceSheet> {
  late DateTime _date;
  OperationalSlot? _chosen;

  List<OperationalSlot>? _slots;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final _dateScroll = ScrollController();

  @override
  void dispose() {
    _dateScroll.dispose();
    super.dispose();
  }

  DateTime get _clock => widget.now ?? DateTime.now();

  DateTime? get _currentStart =>
      MonthlySeriesGroup.occurrenceStart(widget.occurrence);
  DateTime? get _currentEnd =>
      MonthlySeriesGroup.occurrenceEnd(widget.occurrence);

  /// The manager picked the slot the session already occupies.
  ///
  /// It is offered on purpose — hiding it would make the current time look
  /// unavailable — but choosing it is not a change. Showing
  /// «8:00 – 9:00 ← سيصبح 8:00 – 9:00» and enabling the button would send the
  /// server an edit that alters nothing, and read to the manager as though
  /// something had happened.
  bool get _isNoChange {
    final chosen = _chosen;
    if (chosen == null) return false;

    return chosen.startAt == _currentStart && chosen.endAt == _currentEnd;
  }

  @override
  void initState() {
    super.initState();
    final start = _currentStart;
    _date = start == null
        ? DateTime(_clock.year, _clock.month, _clock.day)
        : DateTime(start.year, start.month, start.day);
    _fetch();

    // Open on the session's own date rather than at the start of the range.
    // Otherwise the sheet opens with nothing selected and the date being
    // edited scrolled out of sight, which reads as "pick a date" when the
    // manager has not yet decided to change it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelectedDate());
  }

  void _revealSelectedDate() {
    if (!_dateScroll.hasClients) return;

    final index = _days().indexWhere((d) =>
        d.year == _date.year && d.month == _date.month && d.day == _date.day);
    if (index < 0) return;

    // Chip width plus the separator, minus a little so the neighbour peeks
    // and the strip reads as scrollable.
    final offset = (index * (62.w + 8.w)) - 24.w;

    _dateScroll.jumpTo(
      offset.clamp(0, _dateScroll.position.maxScrollExtent),
    );
  }

  /// A week either side of the session, never earlier than today.
  List<DateTime> _days() {
    final base = _currentStart ?? _clock;
    final today = DateTime(_clock.year, _clock.month, _clock.day);

    return List.generate(15, (i) {
      return DateTime(base.year, base.month, base.day)
          .add(Duration(days: i - 7));
    }).where((d) => !d.isBefore(today)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScopeBanner(
          text: 'أنت تعدّل هذا الموعد فقط. بقية مواعيد الحجز الشهري '
              '#${widget.group.reference} لن تتغير.',
        ),
        SizedBox(height: 14.h),
        _current(),
        SizedBox(height: 14.h),
        Text('اختر التاريخ',
            style: AppTextStyles.font14Bold.copyWith(color: AppColors.dark)),
        SizedBox(height: 8.h),
        _datePicker(),
        SizedBox(height: 14.h),
        Text('اختر الوقت',
            style: AppTextStyles.font14Bold.copyWith(color: AppColors.dark)),
        SizedBox(height: 8.h),
        _slotPicker(),
        if (_chosen != null) ...[
          SizedBox(height: 16.h),
          _isNoChange ? _noChangeNotice() : _summary(),
        ],
        SizedBox(height: 16.h),
        _confirmButton(),
      ],
    );
  }

  // ---- What it is now --------------------------------------------------

  Widget _current() {
    final start = _currentStart;
    final end = _currentEnd;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الموعد الحالي',
              style: AppTextStyles.font12SemiBold
                  .copyWith(color: AppColors.dark2)),
          SizedBox(height: 6.h),
          Text(
            start == null ? '—' : '${arabicDayAndDateOf(start)} ${start.year}',
            style: AppTextStyles.font14SemiBold.copyWith(color: AppColors.dark),
          ),
          SizedBox(height: 3.h),
          if (start != null && end != null) _range(start, end),
          SizedBox(height: 6.h),
          Text(
            'الملعب: ${widget.group.branchName}',
            style:
                AppTextStyles.font12Regular.copyWith(color: AppColors.dark2),
          ),
        ],
      ),
    );
  }

  Widget _range(DateTime start, DateTime end, {Color? color}) {
    final style = AppTextStyles.font14Regular
        .copyWith(color: color ?? AppColors.dark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          SlotTime.rangeText((start.hour, start.minute), (end.hour, end.minute)),
          textDirection: TextDirection.ltr,
          style: style,
        ),
        SizedBox(width: 4.w),
        Text(arabicDayPeriodOf(start.hour, start.minute), style: style),
      ],
    );
  }

  // ---- Date ------------------------------------------------------------

  Widget _datePicker() {
    // A week either side of the session, which covers "move it a day or two"
    // without turning the sheet into a calendar.
    final days = _days();

    return SizedBox(
      // Deliberately unscaled. The chip's text is a fixed point size, so a
      // height scaled by ScreenUtil shrinks on a short screen while its
      // contents do not, and the row overflows by a pixel or two.
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
                color: selected ? AppColors.primary : AppColors.inactive3,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.inactive4,
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
                      color: selected ? AppColors.white : AppColors.dark2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${d.day}',
                    style: AppTextStyles.font14Bold.copyWith(
                      color: selected ? AppColors.white : AppColors.dark,
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

  // ---- Slots -----------------------------------------------------------

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
        final start = s.startAt;
        final end = s.endAt;
        if (start == null || end == null) return const SizedBox.shrink();

        final isCurrent = _isCurrentSlot(s);

        return GestureDetector(
          onTap: () => setState(() => _chosen = s),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.inactive4,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _range(
                  start,
                  end,
                  color: selected ? AppColors.white : AppColors.dark,
                ),
                if (isCurrent) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'الموعد الحالي',
                    style: AppTextStyles.font10Regular.copyWith(
                      color: selected ? AppColors.white : AppColors.dark2,
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

  /// The slot the session already occupies is offered even though it reads as
  /// taken — it is taken by this very booking.
  bool _isCurrentSlot(OperationalSlot s) {
    final start = _currentStart;
    if (start == null) return false;

    return s.startAt == start;
  }

  Widget _notice(String text, {VoidCallback? retry}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.font12Regular.copyWith(color: AppColors.dark2),
          ),
          if (retry != null) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: retry,
              child: Text('إعادة المحاولة',
                  style: AppTextStyles.font12SemiBold
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Before → after --------------------------------------------------

  Widget _summary() {
    final chosen = _chosen!;
    final start = chosen.startAt;
    final end = chosen.endAt;
    final from = _currentStart;
    final fromEnd = _currentEnd;
    if (start == null || end == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.lightSuccess,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (from != null && fromEnd != null) ...[
            Text('الموعد الحالي',
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.dark2)),
            SizedBox(height: 3.h),
            Text('${arabicDayAndDateOf(from)} ${from.year}',
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.dark2)),
            _range(from, fromEnd, color: AppColors.dark2),
            SizedBox(height: 9.h),
          ],
          Text('سيصبح',
              style: AppTextStyles.font12SemiBold
                  .copyWith(color: AppColors.success)),
          SizedBox(height: 3.h),
          Text('${arabicDayAndDateOf(start)} ${start.year}',
              style: AppTextStyles.font14Bold.copyWith(color: AppColors.dark)),
          _range(start, end),
          SizedBox(height: 9.h),
          Text(
            'سيتم تعديل هذا الموعد فقط، ولن تتغير بقية مواعيد الحجز الشهري.',
            style:
                AppTextStyles.font12Regular.copyWith(color: AppColors.dark5),
          ),
        ],
      ),
    );
  }

  Widget _noChangeNotice() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16.r, color: AppColors.dark2),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'هذا هو الموعد الحالي بالفعل. اختر وقتًا أو تاريخًا آخر لتغييره.',
              style:
                  AppTextStyles.font12Regular.copyWith(color: AppColors.dark5),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Confirm ---------------------------------------------------------

  Widget _confirmButton() {
    final ready = _chosen != null && !_saving && !_isNoChange;

    return GestureDetector(
      onTap: ready ? _confirm : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: ready ? AppColors.primary : AppColors.inactive4,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            _saving ? 'جارٍ الحفظ…' : 'تأكيد التعديل',
            style: AppTextStyles.font14Bold.copyWith(color: AppColors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final chosen = _chosen!;
    final start = chosen.startAt;
    final end = chosen.endAt;
    if (start == null || end == null) return;

    setState(() => _saving = true);
    final refusal = await widget.onConfirm(start, end);
    if (!mounted) return;

    setState(() {
      _saving = false;
      // A refusal leaves the booking exactly where it was; the sheet stays
      // open so the manager can pick a different time rather than losing
      // everything they just selected.
      _error = refusal;
    });

    if (refusal == null && mounted) Navigator.pop(context);
  }
}
