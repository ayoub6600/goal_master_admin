import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_customer_cubit/add_customer_cubit.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/customer_viewbody.dart';

import 'support/fake_booking_repo.dart';
import 'support/fake_profile_repo.dart';

/// Answers `getCustomer` from a list that the test can change between calls —
/// standing in for the customer actually existing on the server the moment
/// the second request goes out.
class _CustomersFakeProfileRepo extends FakeProfileRepo {
  List<Customer> nextCustomers = const [];
  int getCustomerCalls = 0;

  @override
  Future<Either<Failure, CustomerData>> getCustomer(
    int page, {
    String? search,
  }) async {
    getCustomerCalls++;
    return Right(CustomerData(data: nextCustomers, lastPage: 1));
  }
}

/// Answers `addCustomer` with a fixed id, recording that it was called.
class _AddCustomerFakeBookingRepo extends FakeBookingRepo {
  int addCustomerCalls = 0;

  @override
  Future<Either<Failure, String>> addCustomer({
    required String fullName,
    required String phone,
  }) async {
    addCustomerCalls++;
    return const Right('99');
  }
}

void main() {
  /// The screen reaches for GoRouter (PageWrapper's back button), so it is
  /// pumped through a real router rather than a bare MaterialApp — the same
  /// pattern the booking-periods screen tests use.
  Widget host({
    required CustomerCubit customerCubit,
    required AddCustomerCubit addCustomerCubit,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: customerCubit),
              BlocProvider.value(value: addCustomerCubit),
            ],
            child: const CustomerViewbody(),
          ),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp.router(
        locale: const Locale('ar'),
        routerConfig: router,
        // The success handler raises a toast, which needs OKToast as an
        // ancestor — the same wrapper the real app installs above MaterialApp.
        builder: (context, inner) => OKToast(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: inner!,
          ),
        ),
      ),
    );
  }

  /// A manually-added customer never has a booking. The list must include
  /// them anyway the moment "Add Customer" succeeds — no manual refresh, no
  /// logout/login, no app restart.
  testWidgets(
      'the customers list refreshes itself after Add Customer succeeds',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final profileRepo = _CustomersFakeProfileRepo();
    final bookingRepo = _AddCustomerFakeBookingRepo();
    final customerCubit = CustomerCubit(bookingRepo: profileRepo);
    final addCustomerCubit = AddCustomerCubit(bookingRepo);

    await tester.pumpWidget(host(
      customerCubit: customerCubit,
      addCustomerCubit: addCustomerCubit,
    ));
    await tester.pumpAndSettle();

    // Nobody on the venue's book yet.
    expect(find.text('لا يوجد عملاء'), findsOneWidget);
    expect(profileRepo.getCustomerCalls, 1);

    // The server now has the new customer — as it will for real the moment
    // storeCustomerAsManager() commits, well before the sheet even closes.
    profileRepo.nextCustomers = [
      Customer(id: 99, fullName: 'زبون جديد', phoneNo: '0911111111', phoneVerified: 0),
    ];

    await tester.tap(find.text('اضافة عميل'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'زبون جديد');
    await tester.enterText(find.byType(TextField).at(1), '0911111111');
    await tester.tap(find.text('اضافة'));
    // The success toast has its own dismiss timer — settle past it rather
    // than through it, same as the subscription screen's own tests do.
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // The sheet closed (success was handled) and the SAME CustomerCubit was
    // asked again — this is the fix: nothing else could have made it refetch.
    expect(bookingRepo.addCustomerCalls, 1);
    expect(
      profileRepo.getCustomerCalls,
      2,
      reason: 'Add Customer succeeding must trigger a real refetch, '
          'not just close the sheet.',
    );
    expect(find.text('زبون جديد'), findsOneWidget);
    expect(find.text('لا يوجد عملاء'), findsNothing);
  });
}
