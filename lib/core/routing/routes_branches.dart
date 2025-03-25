// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:goal_master_admin/core/routing/routes_keys.dart';
// import 'package:goal_master_admin/features/home/presentation/view/home_view.dart' show HomeView;

// List<StatefulShellBranch> routesBranches = [
//   StatefulShellBranch(
//     routes: <RouteBase>[
//       GoRoute(
//         path: RoutesKeys.kHomeViewTab,
//         builder: (context, state) => MultiBlocProvider(providers: [
//           BlocProvider<FetchSpecialtiesCubit>(
//             create: (context) => FetchSpecialtiesCubit(getIt<HomeRepoImp>()),
//           ),
//           BlocProvider<FetchServicesCubit>(
//             create: (context) => FetchServicesCubit(getIt<HomeRepoImp>()),
//           ),
//           BlocProvider<FetchTopDoctorsCubit>(
//             create: (context) => FetchTopDoctorsCubit(getIt<HomeRepoImp>()),
//           ),
//           //FetchTopDoctorsCubit
//         ], child: const HomeView()),
//       ),
//     ],
//   ),
//   StatefulShellBranch(
//     routes: <RouteBase>[
//       GoRoute(
//         path: RoutesKeys.kReservationsTab,
//         builder: (context, state) => const BookingView(),
//       ),
//     ],
//   ),
//   StatefulShellBranch(
//     routes: <RouteBase>[
//       GoRoute(
//         path: RoutesKeys.kServiceTab,
//         builder: (context, state) => const ServicesView(),
//       ),
//     // ],
//   ),
//   StatefulShellBranch(
//     routes: <RouteBase>[
//       GoRoute(
//         path: RoutesKeys.kFavTab,
//         builder: (context, state) => MultiBlocProvider(providers: [
//           BlocProvider<FavToggleCubit>(
//             create: (context) => FavToggleCubit(),
//           ),
//         ], child: const FavoritesView()),
//       ),
//     ],
//   ),
//   StatefulShellBranch(
//     routes: <RouteBase>[
//       GoRoute(
//         path: RoutesKeys.kAccountTab,
//         builder: (context, state) => const DummyAddPatientView(
//           title: 'الحساب',
//         ),
//       ),
//     ],
//   ),
// ];
