import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/subscription_plan_card.dart';

import 'support/fake_subscription_repo.dart';

/// A capability the plan has, one it does not, and a price it charges are
/// three different statements and must not look alike.
///
/// The card previously drew every non-advantage with the same faded minus
/// icon, so agreeing to pay 10% commission looked identical to being denied
/// the marketplace altogether. Feature state comes from the plan's structured
/// values; the Arabic wording is presentation only.
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required bool marketplace,
    double prepaid = 10,
    double poa = 5,
  }) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final plan = FakeSubscriptionRepo.planOption(
      id: marketplace ? 5 : 3,
      name: marketplace ? 'نمو' : 'إدارة',
      code: marketplace ? 'gm_growth' : 'gm_management',
      monthly: marketplace ? 179 : 149,
      marketplace: marketplace,
      prepaidCommission: prepaid,
      poaCommission: poa,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        useInheritedMediaQuery: true,
        builder: (context, child) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: SubscriptionPlanCard(
                  plan: plan,
                  billingCycle: 'monthly',
                  isSelected: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  /// The icon rendered beside a given line of text.
  Icon iconFor(WidgetTester tester, String text) {
    final row = find.ancestor(of: find.text(text), matching: find.byType(Row));
    return tester.widget<Icon>(
      find.descendant(of: row.first, matching: find.byType(Icon)).first,
    );
  }

  const green = Color(0xFF4CD964);
  const red = Color(0xFFFF5A5A);

  // ---------- 12: management-only ----------

  group('a management-only plan', () {
    testWidgets('marks what it gives with a green check', (tester) async {
      await pumpCard(tester, marketplace: false);

      for (final line in [
        'نظام إدارة كامل لملعبك وزبائنك',
        'حجوزاتك المباشرة بدون عمولة',
      ]) {
        final icon = iconFor(tester, line);
        expect(icon.icon, Icons.check_circle, reason: line);
        expect(icon.color, green, reason: line);
      }
    });

    testWidgets('marks the marketplace absences with a red X', (tester) async {
      await pumpCard(tester, marketplace: false);

      for (final line in [
        'ملعبك لا يظهر للزبائن في تطبيق Goal Master',
        'لا تحصل على حجوزات من سوق Goal Master',
      ]) {
        expect(find.text(line), findsOneWidget);

        final icon = iconFor(tester, line);
        expect(icon.icon, Icons.cancel, reason: line);
        expect(icon.color, red, reason: line);
      }
    });

    testWidgets('never uses a neutral minus for an absence', (tester) async {
      await pumpCard(tester, marketplace: false);

      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });
  });

  // ---------- 13: marketplace-enabled ----------

  group('a marketplace plan', () {
    testWidgets('marks visibility and bookings with green checks',
        (tester) async {
      await pumpCard(tester, marketplace: true);

      for (final line in [
        'ملعبك يظهر للزبائن في تطبيق Goal Master',
        'تستقبل حجوزات من Goal Master',
      ]) {
        expect(find.text(line), findsOneWidget);

        final icon = iconFor(tester, line);
        expect(icon.icon, Icons.check_circle, reason: line);
        expect(icon.color, green, reason: line);
      }
    });
  });

  // ---------- 14: commission is a term, not a missing feature ----------

  group('commission', () {
    testWidgets('shows the configured percentages, not hardcoded ones',
        (tester) async {
      // Deliberately unusual values: if these were hardcoded anywhere the
      // card could not render them.
      await pumpCard(tester, marketplace: true, prepaid: 7.5, poa: 2.5);

      expect(find.text('عمولة الدفع المسبق: 7.5%'), findsOneWidget);
      expect(find.text('عمولة الدفع عند الملعب: 2.5%'), findsOneWidget);
    });

    testWidgets('is rendered affirmatively, never as a red X', (tester) async {
      await pumpCard(tester, marketplace: true, prepaid: 10, poa: 5);

      final prepaid = iconFor(tester, 'عمولة الدفع المسبق: 10%');
      final poa = iconFor(tester, 'عمولة الدفع عند الملعب: 5%');

      for (final icon in [prepaid, poa]) {
        expect(icon.icon, Icons.check_circle);
        expect(icon.color, green,
            reason: 'a commercial term is not a capability withheld');
        expect(icon.icon, isNot(Icons.cancel));
      }
    });

    testWidgets('a zero-commission plan says so once, positively',
        (tester) async {
      await pumpCard(tester, marketplace: true, prepaid: 0, poa: 0);

      final line = '0% عمولة على كل حجوزات Goal Master';
      expect(find.text(line), findsOneWidget);
      expect(iconFor(tester, line).color, green);
    });
  });
}
