import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';

/// One of the three stages a manager works through before the venue can take
/// bookings.
class SetupStage {
  const SetupStage({required this.label, required this.done});

  final String label;
  final bool done;

  /// The stages, in the order they are worked through on screen.
  ///
  /// Each `done` flag comes from the server's own setup status rather than from
  /// whatever happens to be filled in on screen, so the tracker keeps telling
  /// the truth after a save fails or the manager reopens the screen.
  static List<SetupStage> of(SetupStatus? setup) => [
        SetupStage(
          label: 'بيانات الشركة',
          done: setup?.hasBranchProfile ?? false,
        ),
        SetupStage(
          label: 'الفئة والخدمات',
          done: (setup?.hasCategorySetup ?? false) &&
              (setup?.hasServiceSetup ?? false),
        ),
        SetupStage(
          label: 'فترات الحجز',
          done: setup?.hasEmployeeSetup ?? false,
        ),
      ];

  /// Index of the stage the manager is on right now — the first unfinished
  /// one, or `-1` once every stage is done.
  static int currentIndexOf(List<SetupStage> stages) =>
      stages.indexWhere((stage) => !stage.done);
}
