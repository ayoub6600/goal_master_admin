import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/venue_block_sheet.dart';

Widget _app() => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const MaterialApp(home: Scaffold(body: SizedBox())),
    );

void main() {
  testWidgets('confirm is disabled until a reason is picked', (tester) async {
    await tester.pumpWidget(_app());
    final context = tester.element(find.byType(Scaffold));

    VenueBlockDecision? result;
    unawaited(VenueBlockSheet.show(context).then((r) => result = r));
    await tester.pumpAndSettle();

    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'تأكيد الحظر'),
    );
    expect(confirmButton.onPressed, isNull,
        reason: 'no reason picked yet — must not be submittable');

    await tester.tap(find.text('مبالغ غير مسددة'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تأكيد الحظر'));
    await tester.pumpAndSettle();

    expect(result?.reasonCode, 'unpaid_amounts');
    expect(result?.note, isNull);
  });

  testWidgets('an optional note is carried through', (tester) async {
    await tester.pumpWidget(_app());
    final context = tester.element(find.byType(Scaffold));

    VenueBlockDecision? result;
    unawaited(VenueBlockSheet.show(context).then((r) => result = r));
    await tester.pumpAndSettle();

    await tester.tap(find.text('سلوك غير مناسب'));
    await tester.enterText(find.byType(TextField), 'تصرف بشكل غير لائق مع الموظفين');
    await tester.pumpAndSettle();

    await tester.tap(find.text('تأكيد الحظر'));
    await tester.pumpAndSettle();

    expect(result?.reasonCode, 'inappropriate_behavior');
    expect(result?.note, 'تصرف بشكل غير لائق مع الموظفين');
  });

  testWidgets('unblock sheet returns true only on explicit confirm', (tester) async {
    await tester.pumpWidget(_app());
    final context = tester.element(find.byType(Scaffold));

    bool? result;
    unawaited(VenueUnblockConfirmSheet.show(context).then((r) => result = r));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}

// Small local helper so this file needs no extra package import for one call.
void unawaited(Future<void> future) {}
