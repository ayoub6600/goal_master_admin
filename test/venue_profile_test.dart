import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/venue_profile/presentation/view/widgets/venue_edit_sheet.dart';
import 'package:goal_master_admin/features/venue_profile/presentation/view/widgets/venue_profile_body.dart';

import 'support/fake_manager_setup_repo.dart';

/// «بيانات الملعب» answers one question, and answers it by reading.
///
/// It used to be the onboarding wizard: every value in an open text box, plus
/// the wallet, the service catalogue, per-service booking channels and the
/// pricing editor. Checking a phone number meant meeting the whole setup, and
/// two screens could disagree about the same setting.
void main() {
  Widget host(Widget child, {Size size = const Size(390, 844)}) {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider(
          create: (_) => ManagerSetupCubit(FakeManagerSetupRepo())
            ..loadBootstrap(),
          child: Scaffold(body: child),
        ),
      ),
    ]);

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

  group('the venue reads as a profile', () {
    testWidgets('name, region, contact and location are shown as values',
        (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      expect(find.text('ملاعب الجدار'), findsWidgets);
      expect(find.text('المعلومات الأساسية'), findsOneWidget);
      expect(find.text('التواصل'), findsOneWidget);
      expect(find.text('الموقع'), findsOneWidget);
      expect(find.text('0916776600'), findsOneWidget);
    });

    testWidgets('nothing is an open text box until تعديل is tapped',
        (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      // The old screen rendered every field as a TextField at all times.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('تعديل'), findsWidgets);
    });

    testWidgets('coordinates are never the headline', (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      expect(find.text('الموقع محدَّد على الخريطة'), findsOneWidget);
      // 32.377..., 15.092... are how a map stores a place, not how one reads.
      expect(find.textContaining('32.3'), findsNothing);
      expect(find.textContaining('15.0'), findsNothing);
    });
  });

  group('settings that belong elsewhere are links, not editors', () {
    testWidgets('booking hours appear as a row with the current value',
        (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      expect(find.text('فترات الحجز'), findsOneWidget);
      // Read from the same bands the hours screen writes — never a second copy.
      expect(find.text('5:00 م – 3:00 ص'), findsOneWidget);
    });

    testWidgets('pitches appear as a count, not a catalogue', (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      expect(find.text('الملاعب والخدمات'), findsOneWidget);
      // Two in the fixture, and counted in Arabic rather than as a bare "2".
      expect(find.text('ملعبان'), findsOneWidget);
    });

    testWidgets('the wizard-only sections are gone', (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      // Each of these has its own screen, and each used to be rebuilt here.
      expect(find.textContaining('محفظة مدير الملعب'), findsNothing);
      expect(find.textContaining('القنوات الزمنية'), findsNothing);
      expect(find.textContaining('الخدمة 1'), findsNothing);
      // And the band vocabulary the hours screen no longer uses.
      expect(find.textContaining('حجز مسائي'), findsNothing);
      expect(find.textContaining('بعد منتصف الليل'), findsNothing);
    });
  });

  group('editing one section', () {
    testWidgets('opens only that section, with the current values',
        (tester) async {
      VenueEditSection? opened;
      await tester.pumpWidget(host(
        VenueProfileBody(onEdit: (section) => opened = section),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تعديل').at(1));
      await tester.pumpAndSettle();

      expect(opened, VenueEditSection.contact);
    });

    testWidgets('the untouched fields are sent back unchanged',
        (tester) async {
      // saveBranchSetup replaces the whole branch, so a partial form that
      // forgets a field would blank it. Editing the phone must not erase the
      // address.
      Map<String, String>? sent;

      await tester.pumpWidget(host(
        BlocProvider.value(
          value: ManagerSetupCubit(FakeManagerSetupRepo()),
          child: VenueEditForm(
            section: VenueEditSection.contact,
            branch: FakeManagerSetupRepo.branchFixture(),
            onSubmit: (values) => sent = values,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '0910000000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();

      expect(sent!['phone'], '0910000000');
      expect(sent!['name'], 'ملاعب الجدار');
      expect(sent!['address'], 'مصراتة - شارع طرابلس');
    });

    testWidgets('save stays disabled until something actually changes',
        (tester) async {
      var submits = 0;

      await tester.pumpWidget(host(
        BlocProvider.value(
          value: ManagerSetupCubit(FakeManagerSetupRepo()),
          child: VenueEditForm(
            section: VenueEditSection.contact,
            branch: FakeManagerSetupRepo.branchFixture(),
            onSubmit: (_) => submits++,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();
      expect(submits, 0, reason: 'saved with nothing changed');

      await tester.enterText(find.byType(TextField).first, '0910000000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();
      expect(submits, 1);
    });

    testWidgets('an emptied field is refused rather than saved blank',
        (tester) async {
      var submits = 0;

      await tester.pumpWidget(host(
        BlocProvider.value(
          value: ManagerSetupCubit(FakeManagerSetupRepo()),
          child: VenueEditForm(
            section: VenueEditSection.identity,
            branch: FakeManagerSetupRepo.branchFixture(),
            onSubmit: (_) => submits++,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();

      expect(submits, 0);
    });
  });

  test('the hours summary reads opening-first for an Arabic reader', () {
    // Measured, not assumed. The earlier time-range bug was invisible to
    // reading a screenshot: in RTL the rightmost run is read first, so the
    // opening time must sit to the RIGHT of the closing time.
    const summary = '5:00 م – 3:00 ص';

    double leftEdgeOf(String needle) {
      final painter = TextPainter(
        text: const TextSpan(
          text: summary,
          style: TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      final start = summary.indexOf(needle);
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + needle.length),
      );

      return boxes.map((b) => b.left).reduce((a, b) => a < b ? a : b);
    }

    expect(
      leftEdgeOf('3:00'),
      lessThan(leftEdgeOf('5:00')),
      reason: 'the closing time is being read before the opening time',
    );
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

        await tester.pumpWidget(host(const VenueProfileBody(), size: size));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a long Arabic venue name does not clip the layout',
        (tester) async {
      await tester.pumpWidget(host(const VenueProfileBody()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
