import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';

/// Stands in for the profile service.
///
/// The subscription screen refreshes the profile after a successful change, so
/// the widget tree needs a ProfileCubit even though these tests assert nothing
/// about it. Only that one call is answered; anything else throws, so a test
/// that starts depending on the profile fails loudly rather than quietly
/// passing on a default.
class FakeProfileRepo implements ProfileRepo {
  int getProfileCalls = 0;

  @override
  Future<Either<Failure, User>> getProfile() async {
    getProfileCalls++;
    return Left(Failure(errMessage: 'profile not exercised in this test'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'FakeProfileRepo received an unexpected ${invocation.memberName}',
      );
}
