import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/repo/manager_signup_repo.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/manager/manager_signup_cubit/manager_signup_cubit.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/manager/subscription_plans_cubit/subscription_plans_cubit.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/manager_signup_flow_body.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/selected_plan_summary.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/subscription_plan_card.dart';
import 'package:oktoast/oktoast.dart';

/// Choosing a plan when signing up.
///
/// Five plans stacked vertically made this page long enough that comparing the
/// first with the last meant remembering it, and the Continue button lived
/// below all of them — so you scrolled past everything to find out what you
/// had chosen. These tests pump the real screen and assert the carousel, the
/// separation of browsing from choosing, and that the decision stays on
/// screen.
///
/// Values here mirror the configured plans: انطلاقة 79 (10%/5%), نمو 179
/// (5%/2.5%), إدارة 149 with the marketplace off.
class _FakeSignupRepo implements ManagerSignupRepo {
  _FakeSignupRepo(this.plans);

  final List<SubscriptionPlanOption> plans;

  @override
  Future<Either<Failure, List<SubscriptionPlanOption>>> getPublicPlans() async =>
      Right(plans);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'the signup flow should not call ${invocation.memberName} here',
      );
}

void main() {
  SubscriptionPlanOption plan({
    required int id,
    required String name,
    required double monthly,
    required double yearly,
    bool marketplace = true,
    double prepaid = 0,
    double poa = 0,
    int trialDays = 30,
    String badge = '',
  }) {
    return SubscriptionPlanOption.fromJson({
      'id': id,
      'name': name,
      'code': 'code_$id',
      'short_description': '',
      'description': '',
      'badge_label': badge,
      'currency_code': 'LYD',
      'monthly_price': monthly,
      'yearly_price': yearly,
      'trial_days': trialDays,
      'is_featured': false,
      'features': {
        'max_branches': 2,
        'max_fields': 6,
        'max_staff': 8,
        'allow_reports': 1,
        'allow_wallet': marketplace ? 1 : 0,
        'allow_local_payment': marketplace ? 1 : 0,
        'allow_customer_marketplace': marketplace ? 1 : 0,
        'goal_master_prepaid_commission_percent': prepaid,
        'goal_master_poa_commission_percent': poa,
      },
    });
  }

  List<SubscriptionPlanOption> configuredPlans() => [
        plan(
            id: 3,
            name: 'إدارة',
            monthly: 149,
            yearly: 1490,
            marketplace: false,
            badge: 'إدارة فقط'),
        plan(
            id: 4,
            name: 'انطلاقة',
            monthly: 79,
            yearly: 790,
            prepaid: 10,
            poa: 5),
        plan(
            id: 5,
            name: 'نمو',
            monthly: 179,
            yearly: 1790,
            prepaid: 5,
            poa: 2.5),
        plan(id: 6, name: 'احتراف', monthly: 349, yearly: 3490),
      ];

  Future<void> pumpFlow(
    WidgetTester tester, {
    Size surface = const Size(390, 844),
    List<SubscriptionPlanOption>? plans,
  }) async {
    tester.view.physicalSize = Size(surface.width * 3, surface.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final repo = _FakeSignupRepo(plans ?? configuredPlans());

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SubscriptionPlansCubit(repo)..loadPlans(),
              ),
              BlocProvider(create: (_) => ManagerSignupCubit(repo)),
            ],
            child: const ManagerSignupFlowBody(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        useInheritedMediaQuery: true,
        builder: (context, child) => MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          builder: (context, child) => OKToast(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  /// What the footer says is chosen.
  ///
  /// Asserted here rather than on card widgets: a card scrolled out of the
  /// carousel's built range no longer exists in the tree, while the footer is
  /// always present — which is the whole point of pinning it.
  String selectedPlanName(WidgetTester tester) {
    return tester
        .widget<SelectedPlanSummary>(find.byType(SelectedPlanSummary))
        .plan
        .name;
  }

  // ---------- 1-2: the carousel ----------

  testWidgets('plans are laid out horizontally, not stacked', (tester) async {
    await pumpFlow(tester);

    expect(find.byType(PageView), findsOneWidget);

    // The neighbouring card peeks, which is what says "there are more".
    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;
    expect(controller.viewportFraction, lessThan(1.0));
  });

  testWidgets('swiping moves between plans', (tester) async {
    await pumpFlow(tester);

    expect(find.text('إدارة'), findsWidgets);

    // Rightwards, because in RTL the next card comes from the left.
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    // A different plan is now centred.
    expect(find.text('انطلاقة'), findsWidgets);
  });

  // ---------- 3-5: browsing is not choosing ----------

  testWidgets('swiping past a plan does not select it', (tester) async {
    await pumpFlow(tester);

    // The first plan is selected on load; the footer says so.
    expect(find.textContaining('إدارة'), findsWidgets);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    // Still chosen: browsing changed the view, not the choice.
    expect(selectedPlanName(tester), 'إدارة',
        reason: 'a swipe must never change what is being bought');
  });

  testWidgets('tapping a plan selects it', (tester) async {
    await pumpFlow(tester);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('انطلاقة').first);
    await tester.pumpAndSettle();

    expect(selectedPlanName(tester), 'انطلاقة');

    // And the card that is on screen shows the selected state.
    final selectedCards = tester
        .widgetList<SubscriptionPlanCard>(find.byType(SubscriptionPlanCard))
        .where((c) => c.isSelected);
    expect(selectedCards.single.plan.name, 'انطلاقة');
  });

  testWidgets('exactly one plan is selected at any time', (tester) async {
    await pumpFlow(tester);

    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();
    }

    // Exactly one plan is chosen, whatever is on screen.
    expect(find.byType(SelectedPlanSummary), findsOneWidget);
    expect(selectedPlanName(tester), isNotEmpty);

    final onScreen = tester
        .widgetList<SubscriptionPlanCard>(find.byType(SubscriptionPlanCard))
        .where((c) => c.isSelected);
    expect(onScreen.length, lessThanOrEqualTo(1),
        reason: 'never two cards claiming to be the choice');
  });

  // ---------- 6-9: the footer ----------

  testWidgets('the footer names the selected plan and its price',
      (tester) async {
    await pumpFlow(tester);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انطلاقة').first);
    await tester.pumpAndSettle();

    expect(find.text('الباقة المختارة'), findsOneWidget);
    // The configured monthly price, not a number the app worked out.
    expect(find.textContaining('79'), findsWidgets);
    expect(find.textContaining('متابعة'), findsWidgets);
  });

  testWidgets('switching to yearly updates the price and keeps the plan',
      (tester) async {
    await pumpFlow(tester);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انطلاقة').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('79'), findsWidgets);

    await tester.tap(find.text('سنوي').first);
    await tester.pumpAndSettle();

    // The configured yearly price, and the same plan still chosen.
    expect(find.textContaining('790'), findsWidgets);

    expect(selectedPlanName(tester), 'انطلاقة',
        reason: 'changing the interval must not lose the chosen plan');
  });

  // ---------- 11-14: honest features ----------

  testWidgets('the management plan marks the marketplace as unavailable',
      (tester) async {
    await pumpFlow(tester);

    // إدارة is the first card, already on screen.
    expect(find.text('ملعبك لا يظهر للزبائن في تطبيق Goal Master'),
        findsOneWidget);
    expect(find.text('لا تحصل على حجوزات من سوق Goal Master'), findsOneWidget);

    final row = find.ancestor(
      of: find.text('ملعبك لا يظهر للزبائن في تطبيق Goal Master'),
      matching: find.byType(Row),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: row.first, matching: find.byType(Icon)).first,
    );

    expect(icon.icon, Icons.cancel);
    expect(icon.color, const Color(0xFFFF5A5A));
  });

  testWidgets('a marketplace plan marks visibility as available',
      (tester) async {
    await pumpFlow(tester);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    // More than one marketplace card can be built at once — the neighbour
    // peeks — so assert the icon on the first of them.
    expect(find.text('ملعبك يظهر للزبائن في تطبيق Goal Master'), findsWidgets);

    final row = find.ancestor(
      of: find.text('ملعبك يظهر للزبائن في تطبيق Goal Master'),
      matching: find.byType(Row),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: row.first, matching: find.byType(Icon)).first,
    );

    expect(icon.icon, Icons.check_circle);
    expect(icon.color, const Color(0xFF4CD964));
  });

  testWidgets('commission renders as a term, with both configured rates',
      (tester) async {
    await pumpFlow(tester);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    // انطلاقة is configured 10% prepaid, 5% pay-on-arrival — two rates, both
    // shown, neither invented.
    expect(find.text('عمولة الدفع المسبق: 10%'), findsOneWidget);
    expect(find.text('عمولة الدفع عند الملعب: 5%'), findsOneWidget);

    final row = find.ancestor(
      of: find.text('عمولة الدفع المسبق: 10%'),
      matching: find.byType(Row),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: row.first, matching: find.byType(Icon)).first,
    );

    expect(icon.icon, Icons.check_circle,
        reason: 'a commercial term is not a missing capability');
    expect(icon.icon, isNot(Icons.cancel));
  });

  // ---------- 15: continue ----------

  testWidgets('continue moves on and charges nothing', (tester) async {
    await pumpFlow(tester);

    await tester.tap(find.textContaining('متابعة').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // The plan step is behind us; no purchase was attempted, and the fake repo
    // would have thrown on any call other than getPublicPlans.
    expect(find.byType(PageView), findsNothing);
  });

  // ---------- 17: it fits ----------

  for (final size in const [
    Size(320, 568), // the smallest phone still supported
    Size(390, 844), // iPhone 17e
    Size(430, 932), // the largest
  ]) {
    testWidgets('lays out without overflow at ${size.width.toInt()}px',
        (tester) async {
      await pumpFlow(tester, surface: size);

      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('الباقة المختارة'), findsOneWidget);
    });
  }
}
