import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo_imp.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/venue_profile/presentation/view/widgets/venue_profile_body.dart';

/// «بيانات الملعب» — the venue's profile, after setup is done.
///
/// The drawer used to send managers to the onboarding wizard for this. That
/// screen exists to CREATE a venue: it asks for services, prices, booking
/// channels and the manager's wallet, and it shows every field as an open text
/// box because a new venue has nothing to read yet. Opening it to check a
/// phone number meant meeting the whole setup again, and editing anything
/// there meant editing settings that now belong to other screens.
///
/// This screen only answers "ما هي بيانات ملعبي؟". Everything that has its own
/// home — booking hours, pitches, the wallet, the subscription — appears here
/// as a link at most, never as a second editor.
///
/// The onboarding screen is deliberately left exactly as it was.
class VenueProfileView extends StatelessWidget {
  const VenueProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ManagerSetupCubit(getIt<ManagerSetupRepoImp>())..loadBootstrap(),
      child: const PageWrapper(
        title: 'بيانات الملعب',
        allowBack: true,
        child: VenueProfileBody(),
      ),
    );
  }
}
