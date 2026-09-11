import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_setup/domain/opening_hours.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/manager_booking_periods_body.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_manager_setup_repo.dart';

/// What the manager is asked, and what the server is told.
///
/// The screen must never put the storage in front of the manager — no
/// «حجز مسائي», no «حجز بعد منتصف الليل», no `24:00:00` — while sending the
/// server exactly the two windows it has always stored.
void main() {
  // PageWrapper draws its own scaffold and reaches for GoRouter's back
  // button, so the screen is pumped through a real router rather than a bare
  // MaterialApp.
  Widget host(Widget child, {Size size = const Size(390, 844)}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider(
            create: (_) => ManagerSetupCubit(FakeManagerSetupRepo()),
            child: child,
          ),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: size,
      builder: (_, __) => MaterialApp.router(
        locale: const Locale('ar'),
        routerConfig: router,
        builder: (context, inner) => Directionality(
          textDirection: TextDirection.rtl,
          child: inner!,
        ),
      ),
    );
  }

  group('the split is invisible to the manager', () {
    test('a 5pm–3am night produces the two stored windows', () {
      const night = OpeningHours(
        opensAt: TimeOfDay(hour: 17, minute: 0),
        closesAt: TimeOfDay(hour: 3, minute: 0),
      );

      // Exactly the payload the old two-switch screen sent by hand.
      expect(night.eveningWindow, ('17:00:00', '24:00:00'));
      expect(night.afterMidnightWindow, ('00:00:00', '03:00:00'));
    });

    test('a venue closing at 11pm switches the second band off', () {
      const early = OpeningHours(
        opensAt: TimeOfDay(hour: 17, minute: 0),
        closesAt: TimeOfDay(hour: 23, minute: 0),
      );

      expect(early.eveningWindow, ('17:00:00', '23:00:00'));
      expect(early.needsAfterMidnight, isFalse);
    });
  });

  /// A host whose bootstrap has actually loaded, so the venue's real pitches
  /// and bands are in hand.
  Widget hostLoaded(Widget child) {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider(
          create: (_) =>
              ManagerSetupCubit(FakeManagerSetupRepo())..loadBootstrap(),
          child: child,
        ),
      ),
    ]);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp.router(
        locale: const Locale('ar'),
        routerConfig: router,
        builder: (context, inner) => Directionality(
          textDirection: TextDirection.rtl,
          child: inner!,
        ),
      ),
    );
  }

  group('an evening-only pitch is not quietly widened', () {
    // The server activates every pitch in the list it is sent and deactivates
    // the rest — per band. A merged list sent to both bands would turn an
    // evening-only pitch into an all-night one just because somebody opened
    // this screen and pressed save.

    testWidgets('saving without touching the pitches preserves the split',
        (tester) async {
      Map<String, List<int>>? sent;

      await tester.pumpWidget(hostLoaded(ManagerBookingPeriodsBody(
        onSave: (_, services) => sent = services,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ ساعات العمل'));
      await tester.pumpAndSettle();

      // The fixture has pitch 1 in both bands and pitch 2 in the evening only.
      expect(sent!['evening'], containsAll(<int>[1, 2]));
      expect(sent!['after_midnight'], contains(1));
      expect(
        sent!['after_midnight'],
        isNot(contains(2)),
        reason: 'an evening-only pitch was widened into the small hours',
      );
    });

    testWidgets('a venue that shuts by midnight sends no late pitches',
        (tester) async {
      Map<String, List<int>>? sent;

      await tester.pumpWidget(hostLoaded(ManagerBookingPeriodsBody(
        onSave: (_, services) => sent = services,
        initialHours: const OpeningHours(
          opensAt: TimeOfDay(hour: 17, minute: 0),
          closesAt: TimeOfDay(hour: 23, minute: 0),
        ),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ ساعات العمل'));
      await tester.pumpAndSettle();

      expect(sent!['after_midnight'], isEmpty);
      expect(sent!['evening'], isNotEmpty);
    });
  });

  group('the old vocabulary is gone from the screen', () {
    testWidgets('no bands, no switches, no machine clocks', (tester) async {
      await tester.pumpWidget(host(const ManagerBookingPeriodsBody()));
      await tester.pumpAndSettle();

      expect(find.text('متى يفتح ملعبك؟'), findsOneWidget);
      expect(find.text('يفتح'), findsOneWidget);
      expect(find.text('يغلق'), findsOneWidget);

      // The concepts the manager should never have been shown.
      expect(find.textContaining('حجز مسائي'), findsNothing);
      expect(find.textContaining('بعد منتصف الليل'), findsNothing);
      expect(find.byType(Switch), findsNothing);

      // And no raw storage values anywhere on screen.
      expect(find.textContaining('24:00:00'), findsNothing);
      expect(find.textContaining('17:00:00'), findsNothing);
      expect(find.textContaining(':00:00'), findsNothing);
    });

    testWidgets('the default night reads back in Arabic', (tester) async {
      await tester.pumpWidget(host(const ManagerBookingPeriodsBody()));
      await tester.pumpAndSettle();

      // The default for a venue with no schedule yet: 16:00 -> 03:00.
      expect(find.text('4:00 م'), findsOneWidget);
      expect(find.text('3:00 ص'), findsOneWidget);
      expect(find.textContaining('ملعبك مفتوح'), findsOneWidget);
    });

    testWidgets('crossing midnight is stated, not asked as a checkbox',
        (tester) async {
      await tester.pumpWidget(host(const ManagerBookingPeriodsBody()));
      await tester.pumpAndSettle();

      expect(find.text('اليوم التالي'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('it lays out on real phones', () {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          host(const ManagerBookingPeriodsBody(), size: size),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the rule that protects night grouping reaches the manager', () {
    test('closing past 6am is refused before anything is sent', () {
      const tooLate = OpeningHours(
        opensAt: TimeOfDay(hour: 17, minute: 0),
        closesAt: TimeOfDay(hour: 9, minute: 0),
      );

      expect(tooLate.isValid, isFalse);
      // Said in the manager's terms, not as a schema rule.
      expect(tooLate.problem, contains('٦:٠٠ صباحًا'));
    });
  });
}
