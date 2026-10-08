import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';

import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/manager_fields_view.dart';

import 'support/fake_manager_setup_repo.dart';

/// Tracks price/sport changes and reflects them in the NEXT getBootstrap()
/// call — standing in for the server actually having saved them.
class _MultiFieldFakeRepo extends FakeManagerSetupRepo {
  double football = 100;
  bool hasBasketball = false;
  int updatePriceCalls = 0;
  int addSportCalls = 0;

  static const _categoryTypes = [
    {'id': 1, 'name': 'قدم'},
    {'id': 2, 'name': 'سلة'},
  ];

  Map<String, dynamic> _service({
    required int id,
    required String title,
    required double price,
    required int categoryTypeId,
    required String categoryName,
  }) {
    return {
      'id': id,
      'title': title,
      'price': price,
      'category_type_id': categoryTypeId,
      'category_name': categoryName,
      'physical_resource': {
        'id': 50,
        'name': 'ملعب تجريبي',
        'type': 'multi',
      },
      'images': const <dynamic>[],
      'supports_evening': true,
      'supports_after_midnight': false,
    };
  }

  @override
  Future<Either<Failure, ManagerSetupBootstrapResponse>> getBootstrap() async {
    final services = [
      _service(
        id: 101,
        title: 'ملعب تجريبي - قدم',
        price: football,
        categoryTypeId: 1,
        categoryName: 'قدم',
      ),
      if (hasBasketball)
        _service(
          id: 102,
          title: 'ملعب تجريبي - سلة',
          price: 80,
          categoryTypeId: 2,
          categoryName: 'سلة',
        ),
    ];

    return Right(ManagerSetupBootstrapResponse.fromJson({
      'data': {
        'setup': {'has_branch_profile': true},
        'wallet': const <String, dynamic>{},
        'zones': const <dynamic>[],
        'category_types': _categoryTypes,
        'catalog': {
          'services': services,
          'employees': const <dynamic>[],
        },
      },
    }));
  }

  @override
  Future<Either<Failure, bool>> updateSportPrice({
    required int resourceId,
    required int serviceId,
    required double price,
  }) async {
    updatePriceCalls++;
    football = price;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> addSportToField({
    required int resourceId,
    required int categoryTypeId,
    required double price,
  }) async {
    addSportCalls++;
    hasBasketball = true;
    return const Right(true);
  }
}

void main() {
  Widget host(ManagerSetupCubit cubit) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider.value(
            value: cubit,
            child: const ManagerFieldsView(),
          ),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp.router(
        locale: const Locale('ar'),
        routerConfig: router,
        builder: (context, inner) => OKToast(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: inner!,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'editing a sport price calls the API and the new price shows without closing the sheet',
      timeout: const Timeout(Duration(seconds: 15)),
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _MultiFieldFakeRepo();
    final cubit = ManagerSetupCubit(repo);

    // loadBootstrap() is awaited AFTER pumpWidget, and directly — not via a
    // zero-delay Future before pumping — so its state is reliably settled
    // before the first expectation.
    await tester.pumpWidget(host(cubit));
    await cubit.loadBootstrap();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Open the (only) field card.
    await tester.tap(find.text('ملعب تجريبي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('100 د.ل'), findsOneWidget);

    // A focused TextField's blinking cursor keeps pumpAndSettle() waiting
    // forever, so steps while the dialog is open use bounded pumps instead.
    await tester.tap(find.text('100 د.ل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The sheet's own "اسم الملعب" TextField is still in the tree under the
    // dialog (the dialog is a separate overlay route, not a replacement) —
    // find.byType(TextField).first silently hits THAT field instead of the
    // dialog's, so the finder must be scoped to the dialog explicitly.
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '120',
    );
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    // The dialog is closed by this tap, so no focused TextField remains —
    // pumpAndSettle() is safe here (it is not safe BEFORE this point, while
    // the dialog's own TextField still has a blinking cursor).
    await tester.pumpAndSettle();

    expect(repo.updatePriceCalls, 1);
    // The sheet is still open and now shows the NEW price live.
    expect(find.text('120 د.ل'), findsOneWidget);
  });

  testWidgets(
      'adding a sport to a multi field calls the API and the new sport appears',
      timeout: const Timeout(Duration(seconds: 15)),
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _MultiFieldFakeRepo();
    final cubit = ManagerSetupCubit(repo);

    await tester.pumpWidget(host(cubit));
    await cubit.loadBootstrap();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('ملعب تجريبي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('إضافة رياضة'), findsOneWidget);

    // A focused TextField's blinking cursor keeps pumpAndSettle() waiting
    // forever, so every step from here uses bounded pumps instead.
    await tester.tap(find.text('إضافة رياضة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Scoped to the dialog for the same reason as the price-edit test above.
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '80',
    );
    await tester.pump();
    await tester.tap(find.text('إضافة').last);
    // The dialog is closed by this tap — see the note above.
    await tester.pumpAndSettle();

    expect(repo.addSportCalls, 1);
    expect(find.text('ملعب تجريبي - سلة'), findsOneWidget);
  });
}
