import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:goal_master_admin/features/manager_subscription/presentation/manager/manager_subscription_cubit/manager_subscription_cubit.dart';
import 'package:goal_master_admin/features/manager_subscription/presentation/view/widgets/manager_subscription_body.dart';

import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';

import 'support/fake_profile_repo.dart';
import 'support/fake_subscription_repo.dart';

/// The subscription screen, rendered.
///
/// Every card used to say «اشترك», which is how the same plan was bought twice
/// inside one cycle. These tests pump the real widget tree against a stubbed
/// server and assert what a manager would actually see and tap — not what a
/// model getter returns.
///
/// The mocked upgrade figures are deliberately odd — 17.43 / 83.91 / 66.48 —
/// so that if the app ever went back to working the proration out for itself,
/// the numbers on screen could not match by accident.
void main() {
  Future<FakeSubscriptionRepo> pumpScreen(
    WidgetTester tester, {
    required FakeSubscriptionRepo repo,
  }) async {
    // A tall surface: this screen is a long scroll of plan cards, and a
    // default 800px test window turns every card into an overflow error that
    // has nothing to do with what is being asserted.
    tester.view.physicalSize = const Size(1170, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // PageWrapper's back button reads GoRouter from context, so the tree needs
    // a real router rather than a bare MaterialApp.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => ManagerSubscriptionCubit(repo)..load(),
              ),
              // The screen refreshes the profile after a successful change.
              BlocProvider(create: (_) => ProfileCubit(FakeProfileRepo())),
            ],
            child: const ManagerSubscriptionBody(),
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
          // The screen raises a success toast, which needs its ancestor —
          // the same wrapper the real app installs above MaterialApp.
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
    return repo;
  }

  /// The manager holds انطلاقة; نمو is an upgrade; إدارة flips the marketplace;
  /// Launch is cheaper in the same family.
  FakeSubscriptionRepo standardRepo({
    Map<String, dynamic>? scheduledChange,
    bool renewalDue = false,
  }) {
    return FakeSubscriptionRepo(
      plans: [
        FakeSubscriptionRepo.planOption(id: 4, name: 'انطلاقة', code: 'gm_start'),
        FakeSubscriptionRepo.planOption(
            id: 5, name: 'نمو', code: 'gm_growth', monthly: 179),
        FakeSubscriptionRepo.planOption(
            id: 3, name: 'إدارة', code: 'gm_management',
            monthly: 149, marketplace: false),
        FakeSubscriptionRepo.planOption(
            id: 1, name: 'Launch', code: 'manager_launch', monthly: 59),
      ],
      current: FakeSubscriptionRepo.currentSubscription(
        scheduledChange: scheduledChange,
      ),
      lifecycle: FakeSubscriptionRepo.lifecycleWith(
        renewalDue: renewalDue,
        [
          FakeSubscriptionRepo.planState(
            id: 4,
            name: 'انطلاقة',
            action: renewalDue ? 'renew' : 'current',
            isCurrent: true,
            effective: 59,
          ),
          FakeSubscriptionRepo.planState(
            id: 5,
            name: 'نمو',
            action: 'upgrade',
            list: 179,
            effective: 179,
            preview: {
              'amount_due': 66.48,
              'unused_current_value': 17.43,
              'target_period_value': 83.91,
              'current_plan_name': 'انطلاقة',
              'cycle_ends_at': '2026-09-29 00:24:51',
            },
          ),
          FakeSubscriptionRepo.planState(
              id: 3, name: 'إدارة', action: 'schedule_switch', list: 149),
          FakeSubscriptionRepo.planState(
              id: 1, name: 'Launch', action: 'schedule_downgrade', list: 59),
        ],
      ),
    );
  }

  /// Scrolls a widget into view before tapping it.
  ///
  /// The screen is a long scroll of plan cards, so most of what these tests
  /// interact with starts below the fold — exactly as it does for a manager.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Selects a plan card by its name.
  Future<void> selectPlan(WidgetTester tester, String planName) async {
    await tapVisible(tester, find.text(planName).first);
  }

  // ---------- 2: the current plan ----------

  testWidgets('the current plan is labelled and not purchasable',
      (tester) async {
    await pumpScreen(tester, repo: standardRepo());

    // The badge, on screen, without tapping anything.
    expect(find.text('باقتك الحالية'), findsWidgets);

    // And no action that would charge for it.
    expect(find.text('اشترك'), findsNothing);
    expect(find.text('ترقية الآن'), findsNothing);
    expect(find.text('تجديد الاشتراك'), findsNothing);
  });

  testWidgets('tapping the current plan sends no request', (tester) async {
    final repo = await pumpScreen(tester, repo: standardRepo());

    await selectPlan(tester, 'انطلاقة');
    await tapVisible(tester, find.text('باقتك الحالية').last);

    expect(repo.changeCalls, 0, reason: 'the plan you hold is not purchasable');
  });

  // ---------- 3: upgrade ----------

  testWidgets('an upgrade renders the server figures in its sheet',
      (tester) async {
    await pumpScreen(tester, repo: standardRepo());

    await selectPlan(tester, 'نمو');
    expect(find.text('ترقية الآن'), findsWidgets);

    await tapVisible(tester, find.text('ترقية الآن').last);

    expect(find.text('ترقية الباقة'), findsOneWidget);
    expect(find.text('الباقة الحالية'), findsOneWidget);
    expect(find.text('الباقة الجديدة'), findsOneWidget);
    expect(find.text('قيمة الفترة المتبقية من باقتك الحالية'), findsOneWidget);
    expect(find.text('قيمة الباقة الجديدة للفترة المتبقية'), findsOneWidget);
    expect(find.text('المبلغ المطلوب الآن'), findsOneWidget);

    // The odd numbers, exactly as the server sent them.
    expect(find.text('17.43 د.ل'), findsOneWidget);
    expect(find.text('83.91 د.ل'), findsOneWidget);
    expect(find.text('66.48 د.ل'), findsOneWidget);

    expect(
      find.text('لن تبدأ دورة جديدة. سيبقى تاريخ انتهاء اشتراكك كما هو.'),
      findsOneWidget,
    );
  });

  // ---------- 4-5: scheduled changes ----------

  testWidgets('a downgrade schedules and promises no charge', (tester) async {
    await pumpScreen(tester, repo: standardRepo());

    await selectPlan(tester, 'Launch');
    expect(find.text('التغيير عند نهاية الدورة'), findsWidgets);

    await tapVisible(tester, find.text('التغيير عند نهاية الدورة').last);

    expect(find.text('تغيير الباقة'), findsOneWidget);
    expect(find.textContaining('ستستمر باقتك الحالية'), findsOneWidget);
    expect(find.textContaining('Launch'), findsWidgets);
    expect(find.textContaining('لن يتم خصم أي مبلغ الآن'), findsOneWidget);
  });

  testWidgets('a marketplace switch is never worded as an upgrade',
      (tester) async {
    await pumpScreen(tester, repo: standardRepo());

    await selectPlan(tester, 'إدارة');
    expect(find.text('تغيير الباقة عند نهاية الدورة'), findsWidgets);

    await tapVisible(tester, find.text('تغيير الباقة عند نهاية الدورة').last);

    expect(find.textContaining('ترقية'), findsNothing);
    expect(
      find.textContaining('لن يتم تغيير مزايا باقتك الحالية الآن'),
      findsOneWidget,
    );
  });

  // ---------- 6-7: the scheduled banner and cancelling it ----------

  testWidgets('a pending change is announced with its plan and date',
      (tester) async {
    await pumpScreen(
      tester,
      repo: standardRepo(scheduledChange: {
        'plan_id': 3,
        'plan_name': 'إدارة',
        'kind': 'switch',
        'effective_at': '2026-09-29 00:24:51',
      }),
    );

    expect(find.text('تغيير مجدول'), findsOneWidget);
    expect(find.textContaining('إدارة'), findsWidgets);
    expect(find.textContaining('سبتمبر'), findsWidgets);
    expect(find.text('إلغاء التغيير'), findsWidgets);
  });

  testWidgets('cancelling a pending change calls the server once and reloads',
      (tester) async {
    final repo = standardRepo(scheduledChange: {
      'plan_id': 3,
      'plan_name': 'إدارة',
      'kind': 'switch',
      'effective_at': '2026-09-29 00:24:51',
    });

    // After cancelling, the server no longer reports a scheduled change.
    repo.currentAfterChange = FakeSubscriptionRepo.currentSubscription();
    repo.lifecycleAfterChange = repo.lifecycle;

    await pumpScreen(tester, repo: repo);
    final reloadsBefore = repo.lifecycleCalls;

    await tapVisible(tester, find.text('إلغاء التغيير').first);

    expect(find.text('إلغاء تغيير الباقة؟'), findsOneWidget);

    await tester.tap(find.text('إلغاء التغيير').last);
    await tester.pumpAndSettle();

    expect(repo.cancelCalls, 1);
    expect(repo.lifecycleCalls, greaterThan(reloadsBefore),
        reason: 'state is re-read from the server, not patched locally');
    expect(find.text('تغيير مجدول'), findsNothing);
  });

  // ---------- 8: double tap ----------

  testWidgets('confirming an upgrade twice sends one request', (tester) async {
    final repo = standardRepo();
    await pumpScreen(tester, repo: repo);

    await selectPlan(tester, 'نمو');
    await tapVisible(tester, find.text('ترقية الآن').last);

    // Two rapid taps on the confirm action, before the first settles.
    final confirm = find.text('تأكيد الترقية');
    await tester.tap(confirm);
    await tester.pump();

    // The success toast schedules a three-second dismissal, so let it expire
    // rather than leaving a pending timer behind.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(repo.changeCalls, 1,
        reason: 'the in-flight guard stops a second submission');
  });

  // ---------- 9: refresh after success ----------

  testWidgets('after a successful upgrade the card reflects the server',
      (tester) async {
    final repo = standardRepo();

    // What the server reports once نمو is the plan they hold.
    repo.currentAfterChange = FakeSubscriptionRepo.currentSubscription(
      planId: 5,
      planName: 'نمو',
    );
    repo.lifecycleAfterChange = FakeSubscriptionRepo.lifecycleWith([
      FakeSubscriptionRepo.planState(
          id: 4, name: 'انطلاقة', action: 'schedule_downgrade'),
      FakeSubscriptionRepo.planState(
          id: 5, name: 'نمو', action: 'current', isCurrent: true, list: 179),
      FakeSubscriptionRepo.planState(
          id: 3, name: 'إدارة', action: 'schedule_switch', list: 149),
      FakeSubscriptionRepo.planState(
          id: 1, name: 'Launch', action: 'schedule_downgrade', list: 59),
    ]);

    await pumpScreen(tester, repo: repo);

    await selectPlan(tester, 'نمو');
    await tapVisible(tester, find.text('ترقية الآن').last);
    await tester.tap(find.text('تأكيد الترقية'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // نمو is now the current plan, and the upgrade action is gone — because
    // the screen re-read the server, not because the test patched a card.
    expect(find.text('باقتك الحالية'), findsWidgets);
    expect(find.text('ترقية الآن'), findsNothing);
  });

  // ---------- 10: a refused payment ----------

  testWidgets('an unaffordable upgrade leaves the current plan in place',
      (tester) async {
    final repo = standardRepo();
    repo.changeResult = Left(FakeSubscriptionRepo.insufficientBalance());

    await pumpScreen(tester, repo: repo);

    await selectPlan(tester, 'نمو');
    await tapVisible(tester, find.text('ترقية الآن').last);
    await tester.tap(find.text('تأكيد الترقية'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // The plan did not change under them, and نمو is still an upgrade.
    expect(find.text('ترقية الآن'), findsWidgets);
    expect(repo.changeCalls, 1);
  });

  // ---------- the false-success bug ----------

  testWidgets('an upgrade that did not take effect is not called a success',
      (tester) async {
    final repo = standardRepo();

    // The shape of the real failure: the server answers successfully — as it
    // does for an event it considers already processed — but the reloaded
    // state still shows the old plan.
    repo.currentAfterChange = FakeSubscriptionRepo.currentSubscription();
    repo.lifecycleAfterChange = repo.lifecycle;

    await pumpScreen(tester, repo: repo);

    await selectPlan(tester, 'نمو');
    await tapVisible(tester, find.text('ترقية الآن').last);
    await tester.tap(find.text('تأكيد الترقية'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(
      find.text('تم تحديث اشتراكك بنجاح.'),
      findsNothing,
      reason: 'the plan never moved, so this is not a success',
    );
    expect(
      find.textContaining('تعذر تأكيد ترقية الباقة'),
      findsWidgets,
    );

    // And نمو is still offered as an upgrade, because it still is one.
    expect(find.text('ترقية الآن'), findsWidgets);
  });

  testWidgets('an upgrade that did take effect is called a success',
      (tester) async {
    final repo = standardRepo();

    repo.currentAfterChange = FakeSubscriptionRepo.currentSubscription(
      planId: 5,
      planName: 'نمو',
    );
    repo.lifecycleAfterChange = FakeSubscriptionRepo.lifecycleWith([
      FakeSubscriptionRepo.planState(
          id: 4, name: 'انطلاقة', action: 'schedule_downgrade'),
      FakeSubscriptionRepo.planState(
          id: 5, name: 'نمو', action: 'current', isCurrent: true, list: 179),
      FakeSubscriptionRepo.planState(
          id: 3, name: 'إدارة', action: 'schedule_switch', list: 149),
      FakeSubscriptionRepo.planState(
          id: 1, name: 'Launch', action: 'schedule_downgrade', list: 59),
    ]);

    await pumpScreen(tester, repo: repo);

    await selectPlan(tester, 'نمو');
    await tapVisible(tester, find.text('ترقية الآن').last);
    await tester.tap(find.text('تأكيد الترقية'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.textContaining('تعذر تأكيد'), findsNothing);
    expect(find.text('باقتك الحالية'), findsWidgets);
    expect(find.text('ترقية الآن'), findsNothing);
  });

  /// A scheduled change legitimately leaves the current plan alone, so it must
  /// not be caught by the confirmation check meant for immediate ones.
  testWidgets('a scheduled downgrade is not reported as unconfirmed',
      (tester) async {
    final repo = standardRepo();
    repo.currentAfterChange = FakeSubscriptionRepo.currentSubscription();
    repo.lifecycleAfterChange = repo.lifecycle;

    await pumpScreen(tester, repo: repo);

    await selectPlan(tester, 'Launch');
    await tapVisible(tester, find.text('التغيير عند نهاية الدورة').last);
    await tester.tap(find.text('تأكيد التغيير'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.textContaining('تعذر تأكيد'), findsNothing);
  });
}
