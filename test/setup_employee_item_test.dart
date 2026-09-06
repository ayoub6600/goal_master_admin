import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';

/// A backend identifier-shortening fix ('GM-BRANCH-{id}-AFTER-MIDNIGHT'
/// overflowed sch_employees.employee_id, varchar(20)) silently broke three
/// separate `.contains('EVENING')` / `.contains('AFTER-MIDNIGHT')` checks
/// scattered across this app — every reload showed the venue closing at
/// midnight instead of its real after-midnight time, because the
/// after-midnight band was never found. These pin the channel classification
/// against both the new short format actually in production and the old
/// long format, in case any row is ever read before its own rename migration
/// runs.
void main() {
  SetupEmployeeItem item(String employeeId) => SetupEmployeeItem.fromJson({
        'id': 1,
        'full_name': 'x',
        'employee_id': employeeId,
        'status': 1,
        'designation_name': '',
        'start_time': '00:00:00',
        'end_time': '00:00:00',
      });

  test('the current short format is classified correctly', () {
    expect(item('GM2-EVE').isEveningChannel, isTrue);
    expect(item('GM2-EVE').isAfterMidnightChannel, isFalse);

    expect(item('GM2-AFT').isAfterMidnightChannel, isTrue);
    expect(item('GM2-AFT').isEveningChannel, isFalse);
  });

  test('the old long format still classifies correctly', () {
    expect(item('GM-BRANCH-2-EVENING').isEveningChannel, isTrue);
    expect(item('GM-BRANCH-2-AFTER-MIDNIGHT').isAfterMidnightChannel, isTrue);
  });

  test('an unrelated employee_id matches neither channel', () {
    final realStaff = item('EMP-0042');
    expect(realStaff.isEveningChannel, isFalse);
    expect(realStaff.isAfterMidnightChannel, isFalse);
  });
}
