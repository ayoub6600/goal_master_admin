// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:goal_master_admin/core/routing/routes_keys.dart';
// import 'package:goal_master_admin/features/home/presentation/view/home_view.dart';

// final GoRouter router = GoRouter(
//   initialLocation: RoutesKeys.kHomeViewTab,
//   routes: [
//     StatefulShellRoute(
//       builder: (context, state, navigationShell) {
//         return BlocProvider(
//           create: (context) => NavigationCubit(),
//           child: MainLayout(navigationShell),
//         );
//       },
//       branches: [
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: RoutesKeys.kHome,
//               builder: (context, state) => const HomeView(),
//             ),
//           ],
//         ),
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: RoutesKeys.kHome,
//               builder: (context, state) => const HomeView(),
//             ),
//           ],
//         ),
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: RoutesKeys.kHome,
//               builder: (context, state) => const HomeView(),
//             ),
//           ],
//         ),
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: RoutesKeys.kHome,
//               builder: (context, state) => const HomeView(),
//             ),
//           ],
//         ),
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: RoutesKeys.kHome,
//               builder: (context, state) => const HomeView(),
//             ),
//           ],
//         ),
//       ],
//     ),
//   ],
// );
