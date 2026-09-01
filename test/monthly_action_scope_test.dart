import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_actions.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_sheet.dart';

import 'support/monthly_fixtures.dart';

/// The question this screen must never leave open: does this change one
/// session, or the whole month?
///
/// The old screen answered it wrongly. Its green primary button said
/// «الغاء الحجز» on a card that represented a monthly booking, and the sheet it
/// opened was titled «تحديد تاريخ جديد» — a manager could reasonably have read
/// that as rescheduling. What it actually did was deactivate the recurrence
/// and cancel every session from the chosen date onward.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );

  MonthlySeriesGroup series() => MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', status: 4),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06', status: 4),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
      ]).single;

  group('ending a series states its scope before it happens', () {
    testWidgets('the confirmation names the whole booking, the start date, '
        'and what survives', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () => confirmEndSeries(
            context: context,
            group: series(),
            now: DateTime(2026, 9, 8),
            onConfirm: () async => confirmed = true,
          ),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Scope: the whole booking, not the session in front of them.
      expect(find.text('هذا الإجراء يشمل الحجز الشهري بالكامل'), findsOneWidget);
      // The exact date the cancellation starts from.
      expect(find.textContaining('13 سبتمبر 2026 وما بعده'), findsOneWidget);
      // And what is NOT touched.
      expect(find.text('المواعيد السابقة ستبقى محفوظة كما هي.'), findsOneWidget);

      // Nothing has happened yet — the sheet is a question, not the action.
      expect(confirmed, isFalse);
    });

    testWidgets('it is named for what it does, not «الغاء الحجز»',
        (tester) async {
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () => confirmEndSeries(
            context: context,
            group: series(),
            now: DateTime(2026, 9, 8),
            onConfirm: () async {},
          ),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('إنهاء الحجز الشهري'), findsOneWidget);
      expect(find.text('الغاء الحجز'), findsNothing);
      // Never framed as picking a new date.
      expect(find.text('تحديد تاريخ جديد'), findsNothing);
    });

    testWidgets('backing out runs nothing', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () => confirmEndSeries(
            context: context,
            group: series(),
            now: DateTime(2026, 9, 8),
            onConfirm: () async => confirmed = true,
          ),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });

    testWidgets('confirming runs it exactly once', (tester) async {
      var calls = 0;

      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () => confirmEndSeries(
            context: context,
            group: series(),
            now: DateTime(2026, 9, 8),
            onConfirm: () async => calls++,
          ),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إنهاء الحجز الشهري').last);
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('a finished series still describes itself honestly',
        (tester) async {
      // Nothing upcoming: there is no "from this date onward" to promise.
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () => confirmEndSeries(
            context: context,
            group: series(),
            now: DateTime(2026, 10, 10),
            onConfirm: () async {},
          ),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('سيتم إلغاء المواعيد المتبقية في هذا الحجز الشهري.'),
        findsOneWidget,
      );
    });
  });

  group('a single session is visibly a single session', () {
    testWidgets('the scope banner names the booking it will NOT touch',
        (tester) async {
      await tester.pumpWidget(host(const ScopeBanner(
        text: 'هذا الموعد فقط — لن تتأثر بقية مواعيد الحجز الشهري #7',
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('هذا الموعد فقط'), findsOneWidget);
      expect(find.textContaining('لن تتأثر بقية مواعيد'), findsOneWidget);
    });

    testWidgets('its action says «فقط» in the label itself', (tester) async {
      await tester.pumpWidget(host(const ActionTile(
        icon: Icons.event_busy_outlined,
        label: 'إلغاء هذا الموعد فقط',
        subtitle: 'بقية مواعيد الحجز الشهري تبقى كما هي',
        destructive: true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('إلغاء هذا الموعد فقط'), findsOneWidget);
      expect(find.text('بقية مواعيد الحجز الشهري تبقى كما هي'), findsOneWidget);
    });

    testWidgets('the two scopes never share a wording', (tester) async {
      // "إلغاء هذا الموعد فقط" vs "إنهاء الحجز الشهري": different verbs,
      // different nouns. Nothing reads as though it could mean either.
      const single = 'إلغاء هذا الموعد فقط';
      const whole = 'إنهاء الحجز الشهري';

      expect(single.contains(whole), isFalse);
      expect(whole.contains(single), isFalse);
    });
  });

  group('the series sheet lists every session with its own slot', () {
    testWidgets('four sessions, four dates, the replacement marked',
        (tester) async {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', status: 4),
        occurrence(
          id: 2,
          seriesId: 7,
          seq: 2,
          date: '2026-09-06',
          replacement: true,
          startTime: '2026-08-30 22:00:00',
          endTime: '2026-08-30 23:00:00',
        ),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
      ]).single;

      await tester.pumpWidget(host(
        MonthlySeriesSheet(group: group, now: DateTime(2026, 9, 8)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('30 أغسطس 2026'), findsOneWidget);
      expect(find.textContaining('6 سبتمبر 2026'), findsOneWidget);
      expect(find.textContaining('13 سبتمبر 2026'), findsOneWidget);
      expect(find.textContaining('20 سبتمبر 2026'), findsOneWidget);

      // The replacement keeps its own hour rather than the series pattern.
      expect(find.text('موعد بديل'), findsOneWidget);
      expect(find.text(SlotTime.rangeText((22, 0), (23, 0))), findsOneWidget);
      expect(find.text(SlotTime.rangeText((20, 0), (21, 0))), findsNWidgets(3));

      expect(find.text('اكتملت 1 من 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
